import { Imovel } from '@domain/entities/Imovel';
import { ForbiddenError, NotFoundError } from '@domain/errors/DomainError';
import { IAssociacaoRepository } from '@domain/repositories/IAssociacaoRepository';
import { IImovelRepository } from '@domain/repositories/IImovelRepository';

export class ObterImovelPorId {
  constructor(
    private readonly imovelRepo: IImovelRepository,
    private readonly associacaoRepo: IAssociacaoRepository,
  ) {}

  async execute(imovelId: string, requesterId: string): Promise<Imovel> {
    const imovel = await this.imovelRepo.findById(imovelId);
    if (!imovel) throw new NotFoundError('Imóvel não encontrado');

    if (imovel.proprietarioId === requesterId) return imovel;

    const associacao = await this.associacaoRepo.findAtivaByImovelEComodatario(
      imovelId,
      requesterId,
    );
    if (associacao) return imovel;

    throw new ForbiddenError('Você não tem acesso a este imóvel');
  }
}
