import { CriarSolicitacoesPadrao } from '@application/useCases/DocumentoUseCases';
import { EventEnvelope } from '@domain/EventEnvelope';
import { IEventHandler } from './IEventHandler';

export class AssociacaoCriadaHandler implements IEventHandler {
  readonly eventType = 'associacao.criada';

  constructor(private readonly useCase: CriarSolicitacoesPadrao) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      associacaoId: string;
      imovelId: string;
      proprietarioId: string;
      comodatarioId: string;
    };
    const docs = await this.useCase.execute({
      associacaoId: p.associacaoId,
      imovelId: p.imovelId,
      proprietarioId: p.proprietarioId,
      comodatarioId: p.comodatarioId,
    });
    console.log(
      `[AssociacaoCriadaHandler] ${docs.length} solicitação(ões) padrão preparada(s) para associação ${p.associacaoId}`,
    );
  }
}
