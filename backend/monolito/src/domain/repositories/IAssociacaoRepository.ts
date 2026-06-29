import { Associacao } from '../entities/Associacao';

export interface CreateAssociacaoInput {
  imovelId: string;
  comodatarioId: string;
  dataInicio: string;
  dataFim?: string | null;
}

/**
 * Associação enriquecida com o nome do comodatário — usada por listagens.
 */
export interface AssociacaoComNome extends Associacao {
  comodatarioNome: string | null;
}

export interface IAssociacaoRepository {
  create(input: CreateAssociacaoInput): Promise<Associacao>;
  findById(id: string): Promise<Associacao | null>;
  findAtivaByImovelEComodatario(
    imovelId: string,
    comodatarioId: string,
  ): Promise<Associacao | null>;
  findAtivasByImovel(imovelId: string): Promise<AssociacaoComNome[]>;
  encerrar(id: string, dataFim?: string | null): Promise<Associacao>;
}
