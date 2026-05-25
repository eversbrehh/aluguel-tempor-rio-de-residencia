import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '@domain/errors/DomainError';
import { container } from '../container';
import {
  associarComodatarioSchema,
  criarImovelSchema,
} from '../schemas/imovelSchemas';

function requireUser(req: Request): { id: string; email: string } {
  if (!req.user) throw new UnauthorizedError();
  return req.user;
}

export class ImovelController {
  static async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = requireUser(req);
      const dto = criarImovelSchema.parse(req.body);
      const imovel = await container.criarImovel.execute({
        proprietarioId: user.id,
        titulo: dto.titulo,
        endereco: dto.endereco,
        descricao: dto.descricao,
        valorAluguel: dto.valorAluguel,
      });
      res.status(201).json({ data: imovel });
    } catch (err) {
      next(err);
    }
  }

  static async listMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = requireUser(req);
      const imoveis = await container.listarImoveisDoUsuario.execute(user.id);
      res.status(200).json({ data: imoveis });
    } catch (err) {
      next(err);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = requireUser(req);
      const imovel = await container.obterImovelPorId.execute(req.params.id, user.id);
      res.status(200).json({ data: imovel });
    } catch (err) {
      next(err);
    }
  }

  static async associarComodatario(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const user = requireUser(req);
      const dto = associarComodatarioSchema.parse(req.body);
      const associacao = await container.associarComodatario.execute({
        imovelId: req.params.id,
        proprietarioId: user.id,
        comodatarioEmail: dto.comodatarioEmail,
        dataInicio: dto.dataInicio,
        dataFim: dto.dataFim,
      });
      res.status(201).json({ data: associacao });
    } catch (err) {
      next(err);
    }
  }
}
