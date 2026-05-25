import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class AssociacaoEncerradaHandler implements IEventHandler {
  readonly eventType = 'associacao.encerrada';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      associacaoId: string;
      imovelId: string;
      comodatarioId: string;
      proprietarioId: string;
      dataFim?: string | null;
    };

    const data = p.dataFim ? `em ${p.dataFim}` : 'nesta data';

    await this.notificacoes.create({
      usuarioId: p.comodatarioId,
      tipo: 'associacao.encerrada',
      titulo: 'Associação encerrada',
      mensagem: `Sua associação ao imóvel foi encerrada ${data}.`,
      dados: { associacaoId: p.associacaoId, imovelId: p.imovelId },
    });

    await this.notificacoes.create({
      usuarioId: p.proprietarioId,
      tipo: 'associacao.encerrada',
      titulo: 'Associação encerrada',
      mensagem: `A associação ao seu imóvel foi encerrada ${data}.`,
      dados: { associacaoId: p.associacaoId, imovelId: p.imovelId },
    });
  }
}
