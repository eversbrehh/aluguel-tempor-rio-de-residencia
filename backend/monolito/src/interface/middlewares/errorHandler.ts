import { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { DomainError } from '@domain/errors/DomainError';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction,
): void {
  if (err instanceof ZodError) {
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Payload inválido',
        details: err.flatten().fieldErrors,
      },
    });
    return;
  }

  if (err instanceof DomainError) {
    res.status(err.status).json({
      error: { code: err.code, message: err.message },
    });
    return;
  }

  const message = err instanceof Error ? err.message : 'Erro interno';
  // eslint-disable-next-line no-console
  console.error('[errorHandler]', err);
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message },
  });
}
