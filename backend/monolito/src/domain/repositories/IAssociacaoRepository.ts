import { Associacao } from '../entities/Associacao';

export interface CreateAssociacaoInput {
  imovelId: string;
  comodatarioId: string;
  dataInicio: string;
  dataFim?: string | null;
}

export interface IAssociacaoRepository {
  create(input: CreateAssociacaoInput): Promise<Associacao>;
  findAtivaByImovelEComodatario(
    imovelId: string,
    comodatarioId: string,
  ): Promise<Associacao | null>;
}
