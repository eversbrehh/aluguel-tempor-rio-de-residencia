import { Documento } from '@domain/entities/Documento';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from '@domain/errors/DomainError';
import { IDocumentoRepository } from '@domain/repositories/IDocumentoRepository';
import { AssociacaoLookup } from '@infrastructure/lookups/AssociacaoLookup';
import { OutboxRepository } from '@infrastructure/outbox/OutboxRepository';
import { StorageService } from '@infrastructure/storage/StorageService';

function basePayload(d: Documento): Record<string, unknown> {
  return {
    documentoId: d.id,
    associacaoId: d.associacaoId,
    imovelId: d.imovelId,
    proprietarioId: d.proprietarioId,
    comodatarioId: d.comodatarioId,
    tipo: d.tipo,
    titulo: d.titulo,
  };
}

// -----------------------------------------------------------------------
export interface SolicitarDocumentoCommand {
  proprietarioId: string;
  associacaoId: string;
  tipo: string;
  titulo: string;
}

export class SolicitarDocumento {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly outbox: OutboxRepository,
    private readonly lookup: AssociacaoLookup,
  ) {}

  async execute(cmd: SolicitarDocumentoCommand): Promise<Documento> {
    const assoc = await this.lookup.byId(cmd.associacaoId);
    if (assoc.proprietarioId !== cmd.proprietarioId) {
      throw new ForbiddenError('Apenas o proprietário pode solicitar documentos');
    }
    if (assoc.status !== 'ativa') {
      throw new ConflictError('Associação não está ativa');
    }
    const doc = await this.repo.create({
      associacaoId: assoc.associacaoId,
      imovelId: assoc.imovelId,
      proprietarioId: assoc.proprietarioId,
      comodatarioId: assoc.comodatarioId,
      tipo: cmd.tipo,
      titulo: cmd.titulo,
    });
    await this.outbox.insert('documento.solicitado', basePayload(doc), doc.id);
    return doc;
  }
}

// -----------------------------------------------------------------------
export interface SolicitacoesPadraoCommand {
  associacaoId: string;
  imovelId: string;
  proprietarioId: string;
  comodatarioId: string;
}

const SOLICITACOES_PADRAO: Array<{ tipo: string; titulo: string }> = [
  { tipo: 'rg', titulo: 'RG (frente e verso)' },
  { tipo: 'comprovante_renda', titulo: 'Comprovante de renda' },
  { tipo: 'contrato', titulo: 'Contrato de comodato assinado' },
];

/**
 * Disparado pelo evento associacao.criada — cria as solicitações iniciais
 * obrigatórias e enfileira um documento.solicitado por item.
 * Idempotente: se já houver documentos para a associação, não recria.
 */
export class CriarSolicitacoesPadrao {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly outbox: OutboxRepository,
  ) {}

  async execute(input: SolicitacoesPadraoCommand): Promise<Documento[]> {
    const existentes = await this.repo.listByAssociacao(input.associacaoId);
    if (existentes.length > 0) return existentes;

    const criados: Documento[] = [];
    for (const item of SOLICITACOES_PADRAO) {
      const doc = await this.repo.create({
        associacaoId: input.associacaoId,
        imovelId: input.imovelId,
        proprietarioId: input.proprietarioId,
        comodatarioId: input.comodatarioId,
        tipo: item.tipo,
        titulo: item.titulo,
      });
      await this.outbox.insert('documento.solicitado', basePayload(doc), doc.id);
      criados.push(doc);
    }
    return criados;
  }
}

// -----------------------------------------------------------------------
export interface ListarDocumentosQuery {
  userId: string;
  associacaoId?: string;
}

export class ListarDocumentos {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly lookup: AssociacaoLookup,
  ) {}

  async execute(query: ListarDocumentosQuery): Promise<Documento[]> {
    if (query.associacaoId) {
      const assoc = await this.lookup.byId(query.associacaoId);
      if (
        assoc.proprietarioId !== query.userId &&
        assoc.comodatarioId !== query.userId
      ) {
        throw new ForbiddenError('Sem acesso a esta associação');
      }
      return this.repo.listByAssociacao(query.associacaoId);
    }
    const [comoComod, comoProp] = await Promise.all([
      this.repo.listByComodatario(query.userId),
      this.repo.listByProprietario(query.userId),
    ]);
    const seen = new Set<string>();
    const merged: Documento[] = [];
    for (const d of [...comoComod, ...comoProp]) {
      if (!seen.has(d.id)) {
        seen.add(d.id);
        merged.push(d);
      }
    }
    return merged.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }
}

// -----------------------------------------------------------------------
export interface UploadDocumentoCommand {
  comodatarioId: string;
  documentoId: string;
  fileName: string;
  contentType: string;
  body: Buffer;
}

export class EnviarDocumento {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly outbox: OutboxRepository,
    private readonly storage: StorageService,
  ) {}

  async execute(cmd: UploadDocumentoCommand): Promise<Documento> {
    const doc = await this.repo.findById(cmd.documentoId);
    if (!doc) throw new NotFoundError('Documento não encontrado');
    if (doc.comodatarioId !== cmd.comodatarioId) {
      throw new ForbiddenError('Apenas o comodatário pode enviar este documento');
    }
    if (doc.status === 'aprovado') {
      throw new ConflictError('Documento já aprovado, não pode ser reenviado');
    }
    if (!cmd.body || cmd.body.length === 0) {
      throw new ValidationError('Arquivo vazio');
    }

    const { path } = await this.storage.upload(
      doc.associacaoId,
      doc.id,
      cmd.fileName,
      cmd.contentType,
      cmd.body,
    );

    const atualizado = await this.repo.updateStatus(doc.id, 'enviado', {
      storagePath: path,
      observacao: null,
    });

    await this.outbox.insert('documento.enviado', basePayload(atualizado), atualizado.id);
    return atualizado;
  }
}

// -----------------------------------------------------------------------
export class GerarDownloadUrl {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly storage: StorageService,
  ) {}

  async execute(userId: string, documentoId: string): Promise<string> {
    const doc = await this.repo.findById(documentoId);
    if (!doc) throw new NotFoundError('Documento não encontrado');
    if (doc.proprietarioId !== userId && doc.comodatarioId !== userId) {
      throw new ForbiddenError('Sem acesso a este documento');
    }
    if (!doc.storagePath) {
      throw new ConflictError('Documento ainda não possui arquivo enviado');
    }
    return this.storage.createSignedUrl(doc.storagePath);
  }
}

// -----------------------------------------------------------------------
export class AprovarDocumento {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly outbox: OutboxRepository,
  ) {}

  async execute(proprietarioId: string, documentoId: string): Promise<Documento> {
    const doc = await this.repo.findById(documentoId);
    if (!doc) throw new NotFoundError('Documento não encontrado');
    if (doc.proprietarioId !== proprietarioId) {
      throw new ForbiddenError('Apenas o proprietário pode aprovar');
    }
    if (doc.status !== 'enviado') {
      throw new ConflictError(`Só é possível aprovar documentos enviados (atual: ${doc.status})`);
    }
    const atualizado = await this.repo.updateStatus(doc.id, 'aprovado');
    await this.outbox.insert('documento.aprovado', basePayload(atualizado), atualizado.id);
    return atualizado;
  }
}

export class RejeitarDocumento {
  constructor(
    private readonly repo: IDocumentoRepository,
    private readonly outbox: OutboxRepository,
  ) {}

  async execute(
    proprietarioId: string,
    documentoId: string,
    observacao?: string | null,
  ): Promise<Documento> {
    const doc = await this.repo.findById(documentoId);
    if (!doc) throw new NotFoundError('Documento não encontrado');
    if (doc.proprietarioId !== proprietarioId) {
      throw new ForbiddenError('Apenas o proprietário pode rejeitar');
    }
    if (doc.status !== 'enviado') {
      throw new ConflictError(`Só é possível rejeitar documentos enviados (atual: ${doc.status})`);
    }
    const atualizado = await this.repo.updateStatus(doc.id, 'rejeitado', {
      observacao: observacao ?? null,
    });
    await this.outbox.insert(
      'documento.rejeitado',
      { ...basePayload(atualizado), observacao: atualizado.observacao },
      atualizado.id,
    );
    return atualizado;
  }
}
