import type { Request, Response } from 'express';
import { z } from 'zod';
import {
  ConcluirTarefa,
  CriarTarefa,
  ListarTarefas,
} from '@application/useCases/TarefaUseCases';

const createBodySchema = z.object({
  associacaoId: z.string().uuid(),
  titulo: z.string().min(1).max(200),
  descricao: z.string().max(1000).optional().nullable(),
  recorrencia: z.enum(['unica', 'diaria', 'semanal', 'mensal']).optional(),
  prazo: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
});

const listQuerySchema = z.object({
  associacaoId: z.string().uuid().optional(),
  imovelId: z.string().uuid().optional(),
});

export class TarefaController {
  constructor(
    private readonly criar: CriarTarefa,
    private readonly listar: ListarTarefas,
    private readonly concluir: ConcluirTarefa,
  ) {}

  create = async (req: Request, res: Response): Promise<void> => {
    const body = createBodySchema.parse(req.body);
    const tarefa = await this.criar.execute({
      proprietarioId: req.userId!,
      ...body,
    });
    res.status(201).json({ data: tarefa });
  };

  list = async (req: Request, res: Response): Promise<void> => {
    const query = listQuerySchema.parse(req.query);
    const tarefas = await this.listar.execute({ userId: req.userId!, ...query });
    res.json({ data: tarefas });
  };

  concluirById = async (req: Request, res: Response): Promise<void> => {
    const tarefa = await this.concluir.execute(req.userId!, req.params.id);
    res.json({ data: tarefa });
  };
}
