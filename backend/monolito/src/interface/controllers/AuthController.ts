import { NextFunction, Request, Response } from 'express';
import { NotFoundError, UnauthorizedError } from '@domain/errors/DomainError';
import { container } from '../container';
import { loginSchema, registerSchema } from '../schemas/authSchemas';

export class AuthController {
  static async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = registerSchema.parse(req.body);
      const result = await container.registrarUsuario.execute(dto);
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  }

  static async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = loginSchema.parse(req.body);
      const session = await container.loginUsuario.execute(dto.email, dto.password);
      res.status(200).json({ data: session });
    } catch (err) {
      next(err);
    }
  }

  /** GET /api/v1/auth/me — retorna o perfil completo do usuário autenticado. */
  static async me(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const profile = await container.profileRepo.findById(req.user.id);
      if (!profile) throw new NotFoundError('Perfil não encontrado');
      res.status(200).json({
        data: {
          id: profile.id,
          email: req.user.email,
          nome: profile.nome,
          tipo: profile.tipo,
          telefone: profile.telefone,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}
