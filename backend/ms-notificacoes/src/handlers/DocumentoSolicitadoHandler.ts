import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class DocumentoSolicitadoHandler implements IEventHandler {
  readonly eventType = 'documento.solicitado';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      documentoId: string;
      associacaoId: string;
      imovelId: string;
      comodatarioId: string;
      tipo: string;
      titulo: string;
    };

    await this.notificacoes.create({
      usuarioId: p.comodatarioId,
      tipo: 'documento.solicitado',
      titulo: 'Documento solicitado',
      mensagem: `Foi solicitado o envio do documento "${p.titulo}".`,
      dados: {
        documentoId: p.documentoId,
        imovelId: p.imovelId,
        associacaoId: p.associacaoId,
        tipoDocumento: p.tipo,
      },
    });
  }
}
