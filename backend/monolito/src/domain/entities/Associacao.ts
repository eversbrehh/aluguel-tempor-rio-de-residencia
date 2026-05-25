export type StatusAssociacao = 'ativa' | 'encerrada';

export interface Associacao {
  id: string;
  imovelId: string;
  comodatarioId: string;
  dataInicio: string;
  dataFim?: string | null;
  status: StatusAssociacao;
  createdAt: string;
}
