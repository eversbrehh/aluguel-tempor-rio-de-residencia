import { Tarefa, TarefaRecorrencia } from '@domain/entities/Tarefa';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '@domain/errors/DomainError';
import { ITarefaRepository } from '@domain/repositories/ITarefaRepository';
import { OutboxRepository } from '@infrastructure/outbox/OutboxRepository';
import { AssociacaoLookup } from '@infrastructure/lookups/AssociacaoLookup';

export interface CriarTarefaCommand {
  proprietarioId: string;        // do JWT
  associacaoId: string;
  titulo: string;
  descricao?: string | null;
  recorrencia?: TarefaRecorrencia;
  prazo?: string | null;
}

export class CriarTarefa {
  constructor(
    private readonly repo: ITarefaRepository,
    private readonly outbox: OutboxRepository,
    private readonly lookup: AssociacaoLookup,
  ) {}

  async execute(cmd: CriarTarefaCommand): Promise<Tarefa> {
    const assoc = await this.lookup.byId(cmd.associacaoId);
    if (assoc.proprietarioId !== cmd.proprietarioId) {
      throw new ForbiddenError('Apenas o proprietário do imóvel pode criar tarefas');
    }
    if (assoc.status !== 'ativa') {
      throw new ConflictError('Associação não está ativa');
    }

    const tarefa = await this.repo.create({
      associacaoId: assoc.associacaoId,
      imovelId: assoc.imovelId,
      proprietarioId: assoc.proprietarioId,
      comodatarioId: assoc.comodatarioId,
      titulo: cmd.titulo,
      descricao: cmd.descricao,
      recorrencia: cmd.recorrencia,
      prazo: cmd.prazo,
    });

    await this.outbox.insert(
      'tarefa.criada',
      {
        tarefaId: tarefa.id,
        associacaoId: tarefa.associacaoId,
        imovelId: tarefa.imovelId,
        proprietarioId: tarefa.proprietarioId,
        comodatarioId: tarefa.comodatarioId,
        titulo: tarefa.titulo,
        descricao: tarefa.descricao,
        recorrencia: tarefa.recorrencia,
        prazo: tarefa.prazo,
        criadoEm: tarefa.createdAt,
      },
      tarefa.id,
    );

    return tarefa;
  }
}

export class ConcluirTarefa {
  constructor(
    private readonly repo: ITarefaRepository,
    private readonly outbox: OutboxRepository,
  ) {}

  async execute(comodatarioId: string, tarefaId: string): Promise<Tarefa> {
    const tarefa = await this.repo.findById(tarefaId);
    if (!tarefa) throw new NotFoundError('Tarefa não encontrada');
    if (tarefa.comodatarioId !== comodatarioId) {
      throw new ForbiddenError('Apenas o comodatário responsável pode concluir esta tarefa');
    }
    if (tarefa.status !== 'pendente') {
      throw new ConflictError(`Tarefa não está pendente (status: ${tarefa.status})`);
    }

    const concluida = await this.repo.marcarConcluida(tarefaId);

    await this.outbox.insert(
      'tarefa.concluida',
      {
        tarefaId: concluida.id,
        associacaoId: concluida.associacaoId,
        imovelId: concluida.imovelId,
        proprietarioId: concluida.proprietarioId,
        comodatarioId: concluida.comodatarioId,
        titulo: concluida.titulo,
        concluidaEm: concluida.concluidaEm,
      },
      concluida.id,
    );

    return concluida;
  }
}

export interface ListarTarefasQuery {
  userId: string;
  associacaoId?: string;
  imovelId?: string;
}

export class ListarTarefas {
  constructor(
    private readonly repo: ITarefaRepository,
    private readonly lookup: AssociacaoLookup,
  ) {}

  async execute(query: ListarTarefasQuery): Promise<Tarefa[]> {
    // Filtro por associação
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

    // Filtro por imóvel: usa as duas listas e mescla por papel
    if (query.imovelId) {
      const proprietario = await this.repo.listByImovel(query.imovelId);
      const visiveis = proprietario.filter(
        (t) => t.proprietarioId === query.userId || t.comodatarioId === query.userId,
      );
      return visiveis;
    }

    // Sem filtro: retorna o que o usuário pode ver em qualquer papel
    const [comoComod, comoProp] = await Promise.all([
      this.repo.listByComodatario(query.userId),
      this.repo.listByProprietario(query.userId),
    ]);
    const seen = new Set<string>();
    const merged: Tarefa[] = [];
    for (const t of [...comoComod, ...comoProp]) {
      if (!seen.has(t.id)) {
        seen.add(t.id);
        merged.push(t);
      }
    }
    return merged.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }
}

export class ArquivarTarefasDaAssociacao {
  constructor(private readonly repo: ITarefaRepository) {}
  async execute(associacaoId: string): Promise<number> {
    return this.repo.arquivarPendentesDaAssociacao(associacaoId);
  }
}
