import { EventEnvelope } from '@domain/EventEnvelope';
import { IEventHandler } from './IEventHandler';

/**
 * Reservado: ao encerrar associação, marcar documentos pendentes como
 * obsoletos. Por ora apenas loga (eventos idempotentes via DLQ não acontecem).
 */
export class AssociacaoEncerradaHandler implements IEventHandler {
  readonly eventType = 'associacao.encerrada';

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as { associacaoId: string };
    console.log(
      `[AssociacaoEncerradaHandler] associação ${p.associacaoId} encerrada — documentos mantidos para histórico.`,
    );
  }
}
