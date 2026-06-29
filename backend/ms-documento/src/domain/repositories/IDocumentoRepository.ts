import { Documento, DocumentoStatus } from '@domain/entities/Documento';

export interface CreateDocumentoInput {
  associacaoId: string;
  imovelId: string;
  proprietarioId: string;
  comodatarioId: string;
  tipo: string;
  titulo: string;
}

export interface IDocumentoRepository {
  create(input: CreateDocumentoInput): Promise<Documento>;
  findById(id: string): Promise<Documento | null>;
  listByAssociacao(associacaoId: string): Promise<Documento[]>;
  listByComodatario(comodatarioId: string): Promise<Documento[]>;
  listByProprietario(proprietarioId: string): Promise<Documento[]>;
  updateStatus(
    id: string,
    status: DocumentoStatus,
    extra?: { storagePath?: string | null; observacao?: string | null },
  ): Promise<Documento>;
}
