import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '@domain/errors/DomainError';
import { IAuthService } from '@domain/services/IAuthService';

export interface AuthenticatedUser {
  id: string;
  email: string;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export function authMiddleware(authService: IAuthService) {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      const header = req.headers.authorization;
      if (!header || !header.toLowerCase().startsWith('bearer ')) {
        throw new UnauthorizedError('Header Authorization Bearer ausente');
      }

      const token = header.slice(7).trim();
      if (!token) throw new UnauthorizedError('Token vazio');

      const payload = await authService.verifyToken(token);
      req.user = { id: payload.userId, email: payload.email };
      next();
    } catch (err) {
      next(err);
    }
  };
}
