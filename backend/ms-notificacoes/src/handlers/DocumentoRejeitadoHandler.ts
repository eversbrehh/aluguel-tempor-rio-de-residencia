import { EventEnvelope } from '@domain/EventEnvelope';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { IEventHandler } from './IEventHandler';

export class DocumentoRejeitadoHandler implements IEventHandler {
  readonly eventType = 'documento.rejeitado';

  constructor(private readonly notificacoes: NotificacaoRepository) {}

  async handle(event: EventEnvelope): Promise<void> {
    const p = event.payload as {
      documentoId: string;
      associacaoId: string;
      imovelId: string;
      comodatarioId: string;
      titulo: string;
      observacao?: string | null;
    };

    const motivo = p.observacao ? ` Motivo: ${p.observacao}` : '';
    await this.notificacoes.create({
      usuarioId: p.comodatarioId,
      tipo: 'documento.rejeitado',
      titulo: 'Documento rejeitado',
      mensagem: `Seu documento "${p.titulo}" foi rejeitado.${motivo}`,
      dados: {
        documentoId: p.documentoId,
        imovelId: p.imovelId,
        associacaoId: p.associacaoId,
      },
    });
  }
}
