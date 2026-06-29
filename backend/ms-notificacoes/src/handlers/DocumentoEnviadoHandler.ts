import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class DocumentoEnviadoHandler implements IEventHandler {
  readonly eventType = 'documento.enviado';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      documentoId: string;
      associacaoId: string;
      imovelId: string;
      proprietarioId: string;
      titulo: string;
    };

    await this.notificacoes.create({
      usuarioId: p.proprietarioId,
      tipo: 'documento.enviado',
      titulo: 'Documento enviado',
      mensagem: `O comodatário enviou o documento "${p.titulo}" para sua análise.`,
      dados: {
        documentoId: p.documentoId,
        imovelId: p.imovelId,
        associacaoId: p.associacaoId,
      },
    });
  }
}
