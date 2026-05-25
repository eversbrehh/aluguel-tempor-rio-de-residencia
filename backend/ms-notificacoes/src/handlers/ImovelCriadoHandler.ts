import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class ImovelCriadoHandler implements IEventHandler {
  readonly eventType = 'imovel.criado';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const payload = event.payload as {
      imovelId: string;
      proprietarioId: string;
      titulo: string;
      endereco: string;
    };

    await this.notificacoes.create({
      usuarioId: payload.proprietarioId,
      tipo: 'imovel.criado',
      titulo: 'Imóvel cadastrado',
      mensagem: `Seu imóvel "${payload.titulo}" foi cadastrado com sucesso.`,
      dados: { imovelId: payload.imovelId, endereco: payload.endereco },
    });
  }
}
