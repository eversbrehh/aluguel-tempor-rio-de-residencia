import { Imovel } from '@domain/entities/Imovel';
import { ForbiddenError } from '@domain/errors/DomainError';
import { IImovelRepository } from '@domain/repositories/IImovelRepository';
import { IProfileRepository } from '@domain/repositories/IProfileRepository';

export interface CriarImovelDTO {
  proprietarioId: string;
  titulo: string;
  endereco: string;
  descricao?: string | null;
  valorAluguel?: number | null;
}

export class CriarImovel {
  constructor(
    private readonly imovelRepo: IImovelRepository,
    private readonly profileRepo: IProfileRepository,
  ) {}

  async execute(dto: CriarImovelDTO): Promise<Imovel> {
    const profile = await this.profileRepo.findById(dto.proprietarioId);
    if (!profile || profile.tipo !== 'proprietario') {
      throw new ForbiddenError('Apenas proprietários podem cadastrar imóveis');
    }

    return this.imovelRepo.create({
      proprietarioId: dto.proprietarioId,
      titulo: dto.titulo,
      endereco: dto.endereco,
      descricao: dto.descricao,
      valorAluguel: dto.valorAluguel,
    });
  }
}
