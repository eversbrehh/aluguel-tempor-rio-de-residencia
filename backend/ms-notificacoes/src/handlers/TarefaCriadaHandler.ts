import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class TarefaCriadaHandler implements IEventHandler {
  readonly eventType = 'tarefa.criada';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      tarefaId: string;
      associacaoId: string;
      imovelId: string;
      comodatarioId: string;
      titulo: string;
      prazo?: string | null;
    };

    const prazoTxt = p.prazo ? ` (prazo: ${p.prazo})` : '';
    await this.notificacoes.create({
      usuarioId: p.comodatarioId,
      tipo: 'tarefa.criada',
      titulo: 'Nova tarefa',
      mensagem: `Você recebeu a tarefa "${p.titulo}"${prazoTxt}.`,
      dados: { tarefaId: p.tarefaId, imovelId: p.imovelId, associacaoId: p.associacaoId },
    });
  }
}
