import type { Request, Response } from 'express';
import { z } from 'zod';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';

const listQuerySchema = z.object({
  onlyUnread: z
    .union([z.literal('true'), z.literal('false')])
    .optional()
    .transform((v) => v === 'true'),
  limit: z.coerce.number().int().min(1).max(100).optional(),
  cursor: z.string().datetime({ offset: true }).optional(),
});

export class NotificacaoController {
  constructor(private readonly repo: NotificacaoRepository) {}

  list = async (req: Request, res: Response): Promise<void> => {
    const parsed = listQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: parsed.error.flatten().fieldErrors },
      });
      return;
    }
    const result = await this.repo.list({
      usuarioId: req.userId!,
      onlyUnread: parsed.data.onlyUnread,
      limit: parsed.data.limit,
      cursor: parsed.data.cursor,
    });
    res.json({ data: result });
  };

  markAsRead = async (req: Request, res: Response): Promise<void> => {
    const id = req.params.id;
    const notif = await this.repo.markAsRead(req.userId!, id);
    if (!notif) {
      res.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Notificação não encontrada' },
      });
      return;
    }
    res.json({ data: notif });
  };

  markAllAsRead = async (req: Request, res: Response): Promise<void> => {
    const count = await this.repo.markAllAsRead(req.userId!);
    res.json({ data: { updated: count } });
  };
}
