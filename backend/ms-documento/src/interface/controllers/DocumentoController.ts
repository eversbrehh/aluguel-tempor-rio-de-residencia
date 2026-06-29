import type { Request, Response } from 'express';
import { z } from 'zod';
import {
  AprovarDocumento,
  EnviarDocumento,
  GerarDownloadUrl,
  ListarDocumentos,
  RejeitarDocumento,
  SolicitarDocumento,
} from '@application/useCases/DocumentoUseCases';
import { ValidationError } from '@domain/errors/DomainError';

const solicitarBody = z.object({
  associacaoId: z.string().uuid(),
  tipo: z.string().min(1).max(60),
  titulo: z.string().min(1).max(200),
});

const listQuery = z.object({
  associacaoId: z.string().uuid().optional(),
});

const rejeitarBody = z.object({
  observacao: z.string().max(1000).optional(),
});

export class DocumentoController {
  constructor(
    private readonly solicitar: SolicitarDocumento,
    private readonly listar: ListarDocumentos,
    private readonly enviar: EnviarDocumento,
    private readonly gerarDownload: GerarDownloadUrl,
    private readonly aprovar: AprovarDocumento,
    private readonly rejeitar: RejeitarDocumento,
  ) {}

  create = async (req: Request, res: Response): Promise<void> => {
    const body = solicitarBody.parse(req.body);
    const doc = await this.solicitar.execute({ proprietarioId: req.userId!, ...body });
    res.status(201).json({ data: doc });
  };

  list = async (req: Request, res: Response): Promise<void> => {
    const q = listQuery.parse(req.query);
    const docs = await this.listar.execute({ userId: req.userId!, ...q });
    res.json({ data: docs });
  };

  upload = async (req: Request, res: Response): Promise<void> => {
    const file = req.file;
    if (!file) throw new ValidationError('Arquivo (campo "file") é obrigatório');
    const doc = await this.enviar.execute({
      comodatarioId: req.userId!,
      documentoId: req.params.id,
      fileName: file.originalname,
      contentType: file.mimetype || 'application/octet-stream',
      body: file.buffer,
    });
    res.status(200).json({ data: doc });
  };

  download = async (req: Request, res: Response): Promise<void> => {
    const url = await this.gerarDownload.execute(req.userId!, req.params.id);
    res.json({ data: { url } });
  };

  approve = async (req: Request, res: Response): Promise<void> => {
    const doc = await this.aprovar.execute(req.userId!, req.params.id);
    res.json({ data: doc });
  };

  reject = async (req: Request, res: Response): Promise<void> => {
    const body = rejeitarBody.parse(req.body ?? {});
    const doc = await this.rejeitar.execute(req.userId!, req.params.id, body.observacao);
    res.json({ data: doc });
  };
}
