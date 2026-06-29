// Reservado para extensões futuras: criar tarefa-modelo automaticamente ao
// abrir uma nova associação. Mantido como marcador idempotente para que a
// fila tarefas.eventos receba associacao.criada sem ir para DLQ.
import { EventEnvelope } from '@domain/EventEnvelope';
import { IEventHandler } from './IEventHandler';

export class AssociacaoCriadaHandler implements IEventHandler {
  readonly eventType = 'associacao.criada';

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as { associacaoId: string; imovelId: string };
    console.log(
      `[AssociacaoCriadaHandler] associação ${p.associacaoId} (imóvel ${p.imovelId}) registrada — pronto para receber tarefas.`,
    );
  }
}
