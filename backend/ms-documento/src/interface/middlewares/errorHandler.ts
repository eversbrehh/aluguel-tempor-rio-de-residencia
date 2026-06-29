import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { DomainError } from '@domain/errors/DomainError';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction): void {
  if (err instanceof ZodError) {
    res
      .status(400)
      .json({ error: { code: 'VALIDATION_ERROR', message: err.flatten().fieldErrors } });
    return;
  }
  if (err instanceof DomainError) {
    res.status(err.status).json({ error: { code: err.code, message: err.message } });
    return;
  }
  console.error('[HTTP] erro não tratado:', err);
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'Erro interno do servidor' },
  });
}
