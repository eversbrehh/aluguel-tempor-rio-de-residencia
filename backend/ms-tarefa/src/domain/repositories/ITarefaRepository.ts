import { Tarefa } from '@domain/entities/Tarefa';

export interface CreateTarefaInput {
  associacaoId: string;
  imovelId: string;
  proprietarioId: string;
  comodatarioId: string;
  titulo: string;
  descricao?: string | null;
  recorrencia?: Tarefa['recorrencia'];
  prazo?: string | null;
}

export interface ITarefaRepository {
  create(input: CreateTarefaInput): Promise<Tarefa>;
  findById(id: string): Promise<Tarefa | null>;
  listByAssociacao(associacaoId: string): Promise<Tarefa[]>;
  listByImovel(imovelId: string): Promise<Tarefa[]>;
  listByComodatario(comodatarioId: string): Promise<Tarefa[]>;
  listByProprietario(proprietarioId: string): Promise<Tarefa[]>;
  marcarConcluida(id: string): Promise<Tarefa>;
  arquivarPendentesDaAssociacao(associacaoId: string): Promise<number>;
}
