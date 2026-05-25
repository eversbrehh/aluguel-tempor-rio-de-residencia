import { Imovel } from '@domain/entities/Imovel';
import { NotFoundError } from '@domain/errors/DomainError';
import { IImovelRepository } from '@domain/repositories/IImovelRepository';
import { IProfileRepository } from '@domain/repositories/IProfileRepository';

export class ListarImoveisDoUsuario {
  constructor(
    private readonly imovelRepo: IImovelRepository,
    private readonly profileRepo: IProfileRepository,
  ) {}

  async execute(userId: string): Promise<Imovel[]> {
    const profile = await this.profileRepo.findById(userId);
    if (!profile) throw new NotFoundError('Perfil do usuário não encontrado');

    if (profile.tipo === 'proprietario') {
      return this.imovelRepo.findByProprietario(userId);
    }
    return this.imovelRepo.findByComodatarioAtivo(userId);
  }
}
