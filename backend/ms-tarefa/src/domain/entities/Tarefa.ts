export type TarefaRecorrencia = 'unica' | 'diaria' | 'semanal' | 'mensal';
export type TarefaStatus = 'pendente' | 'concluida' | 'arquivada';

export interface Tarefa {
  id: string;
  associacaoId: string;
  imovelId: string;
  proprietarioId: string;
  comodatarioId: string;
  titulo: string;
  descricao: string | null;
  recorrencia: TarefaRecorrencia;
  prazo: string | null;
  status: TarefaStatus;
  concluidaEm: string | null;
  createdAt: string;
}

export interface TarefaRow {
  id: string;
  associacao_id: string;
  imovel_id: string;
  proprietario_id: string;
  comodatario_id: string;
  titulo: string;
  descricao: string | null;
  recorrencia: TarefaRecorrencia;
  prazo: string | null;
  status: TarefaStatus;
  concluida_em: string | null;
  created_at: string;
}

export function rowToTarefa(row: TarefaRow): Tarefa {
  return {
    id: row.id,
    associacaoId: row.associacao_id,
    imovelId: row.imovel_id,
    proprietarioId: row.proprietario_id,
    comodatarioId: row.comodatario_id,
    titulo: row.titulo,
    descricao: row.descricao,
    recorrencia: row.recorrencia,
    prazo: row.prazo,
    status: row.status,
    concluidaEm: row.concluida_em,
    createdAt: row.created_at,
  };
}
