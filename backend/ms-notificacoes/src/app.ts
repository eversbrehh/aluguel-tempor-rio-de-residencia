import cors from 'cors';
import express, { Application, NextFunction, Request, Response } from 'express';
import helmet from 'helmet';
import { env } from '@config/env';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { buildNotificacaoRouter } from '@interface/routes/notificacaoRoutes';

export function buildApp(repo: NotificacaoRepository): Application {
  const app = express();
  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',').map((o) => o.trim()),
      credentials: true,
    }),
  );
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok', service: 'ms-notificacoes', timestamp: new Date().toISOString() });
  });

  app.use(`${env.API_PREFIX}/notificacoes`, buildNotificacaoRouter(repo));

  app.use((_req: Request, res: Response) => {
    res
      .status(404)
      .json({ error: { code: 'NOT_FOUND', message: 'Rota não encontrada' } });
  });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error('[HTTP] erro não tratado:', err);
    res.status(500).json({
      error: { code: 'INTERNAL_ERROR', message: 'Erro interno do servidor' },
    });
  });

  return app;
}
