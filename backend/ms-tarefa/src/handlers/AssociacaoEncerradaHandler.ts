import { EventEnvelope } from '@domain/EventEnvelope';
import { ArquivarTarefasDaAssociacao } from '@application/useCases/TarefaUseCases';
import { IEventHandler } from './IEventHandler';

export class AssociacaoEncerradaHandler implements IEventHandler {
  readonly eventType = 'associacao.encerrada';

  constructor(private readonly useCase: ArquivarTarefasDaAssociacao) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as { associacaoId: string };
    const count = await this.useCase.execute(p.associacaoId);
    console.log(
      `[AssociacaoEncerradaHandler] arquivou ${count} tarefa(s) pendentes da associação ${p.associacaoId}`,
    );
  }
}
