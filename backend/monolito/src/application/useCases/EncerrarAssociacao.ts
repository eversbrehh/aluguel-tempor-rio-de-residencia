import { Associacao } from '@domain/entities/Associacao';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '@domain/errors/DomainError';
import { IAssociacaoRepository } from '@domain/repositories/IAssociacaoRepository';
import { IImovelRepository } from '@domain/repositories/IImovelRepository';

export interface EncerrarAssociacaoDTO {
  imovelId: string;
  associacaoId: string;
  requesterId: string;
  dataFim?: string | null;
}

export class EncerrarAssociacao {
  constructor(
    private readonly imovelRepo: IImovelRepository,
    private readonly associacaoRepo: IAssociacaoRepository,
  ) {}

  async execute(dto: EncerrarAssociacaoDTO): Promise<Associacao> {
    const associacao = await this.associacaoRepo.findById(dto.associacaoId);
    if (!associacao) throw new NotFoundError('Associação não encontrada');

    if (associacao.imovelId !== dto.imovelId) {
      throw new NotFoundError('Associação não pertence ao imóvel informado');
    }

    const imovel = await this.imovelRepo.findById(dto.imovelId);
    if (!imovel) throw new NotFoundError('Imóvel não encontrado');

    if (imovel.proprietarioId !== dto.requesterId) {
      throw new ForbiddenError('Apenas o proprietário pode encerrar a associação');
    }

    if (associacao.status !== 'ativa') {
      throw new ConflictError('Associação já está encerrada');
    }

    return this.associacaoRepo.encerrar(dto.associacaoId, dto.dataFim ?? null);
  }
}
