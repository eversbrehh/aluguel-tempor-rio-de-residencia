import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class AssociacaoCriadaHandler implements IEventHandler {
  readonly eventType = 'associacao.criada';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      associacaoId: string;
      imovelId: string;
      comodatarioId: string;
      proprietarioId: string;
      dataInicio: string;
      dataFim?: string | null;
    };

    // Notifica comodatário
    await this.notificacoes.create({
      usuarioId: p.comodatarioId,
      tipo: 'associacao.criada',
      titulo: 'Nova associação a imóvel',
      mensagem: `Você foi associado a um imóvel a partir de ${p.dataInicio}.`,
      dados: { associacaoId: p.associacaoId, imovelId: p.imovelId },
    });

    // Notifica proprietário
    await this.notificacoes.create({
      usuarioId: p.proprietarioId,
      tipo: 'associacao.criada',
      titulo: 'Comodatário vinculado',
      mensagem: `Um comodatário foi associado ao seu imóvel a partir de ${p.dataInicio}.`,
      dados: { associacaoId: p.associacaoId, imovelId: p.imovelId },
    });
  }
}
