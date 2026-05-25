import { Associacao } from '@domain/entities/Associacao';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '@domain/errors/DomainError';
import { IAssociacaoRepository } from '@domain/repositories/IAssociacaoRepository';
import { IImovelRepository } from '@domain/repositories/IImovelRepository';
import { IProfileRepository } from '@domain/repositories/IProfileRepository';

export interface AssociarComodatarioDTO {
  imovelId: string;
  proprietarioId: string;
  comodatarioEmail: string;
  dataInicio: string;
  dataFim?: string | null;
}

export class AssociarComodatario {
  constructor(
    private readonly imovelRepo: IImovelRepository,
    private readonly profileRepo: IProfileRepository,
    private readonly associacaoRepo: IAssociacaoRepository,
  ) {}

  async execute(dto: AssociarComodatarioDTO): Promise<Associacao> {
    const imovel = await this.imovelRepo.findById(dto.imovelId);
    if (!imovel) throw new NotFoundError('Imóvel não encontrado');

    if (imovel.proprietarioId !== dto.proprietarioId) {
      throw new ForbiddenError('Apenas o proprietário do imóvel pode associar comodatários');
    }

    const comodatario = await this.profileRepo.findByEmail(dto.comodatarioEmail);
    if (!comodatario) throw new NotFoundError('Comodatário não encontrado');

    if (comodatario.tipo !== 'comodatario') {
      throw new ForbiddenError('O usuário informado não é um comodatário');
    }

    const existente = await this.associacaoRepo.findAtivaByImovelEComodatario(
      dto.imovelId,
      comodatario.id,
    );
    if (existente) {
      throw new ConflictError('Comodatário já possui associação ativa neste imóvel');
    }

    return this.associacaoRepo.create({
      imovelId: dto.imovelId,
      comodatarioId: comodatario.id,
      dataInicio: dto.dataInicio,
      dataFim: dto.dataFim,
    });
  }
}
