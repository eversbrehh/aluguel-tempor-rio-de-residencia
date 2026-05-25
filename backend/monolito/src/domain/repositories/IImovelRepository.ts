import { Imovel } from '../entities/Imovel';

export interface CreateImovelInput {
  proprietarioId: string;
  titulo: string;
  endereco: string;
  descricao?: string | null;
  valorAluguel?: number | null;
}

export interface IImovelRepository {
  create(input: CreateImovelInput): Promise<Imovel>;
  findById(id: string): Promise<Imovel | null>;
  findByProprietario(proprietarioId: string): Promise<Imovel[]>;
  findByComodatarioAtivo(comodatarioId: string): Promise<Imovel[]>;
}
