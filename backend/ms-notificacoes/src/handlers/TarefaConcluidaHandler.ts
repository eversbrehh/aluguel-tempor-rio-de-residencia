import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class TarefaConcluidaHandler implements IEventHandler {
  readonly eventType = 'tarefa.concluida';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      tarefaId: string;
      associacaoId: string;
      imovelId: string;
      proprietarioId: string;
      titulo: string;
      concluidaEm?: string;
    };

    await this.notificacoes.create({
      usuarioId: p.proprietarioId,
      tipo: 'tarefa.concluida',
      titulo: 'Tarefa concluída',
      mensagem: `A tarefa "${p.titulo}" foi concluída pelo comodatário.`,
      dados: { tarefaId: p.tarefaId, imovelId: p.imovelId, associacaoId: p.associacaoId },
    });
  }
}
