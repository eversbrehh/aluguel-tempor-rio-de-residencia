import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class DocumentoAprovadoHandler implements IEventHandler {
  readonly eventType = 'documento.aprovado';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      documentoId: string;
      associacaoId: string;
      imovelId: string;
      comodatarioId: string;
      titulo: string;
    };

    await this.notificacoes.create({
      usuarioId: p.comodatarioId,
      tipo: 'documento.aprovado',
      titulo: 'Documento aprovado',
      mensagem: `Seu documento "${p.titulo}" foi aprovado pelo proprietário.`,
      dados: {
        documentoId: p.documentoId,
        imovelId: p.imovelId,
        associacaoId: p.associacaoId,
      },
    });
  }
}
