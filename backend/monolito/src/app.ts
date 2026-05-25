import cors from 'cors';
import express, { Application, Request, Response } from 'express';
import helmet from 'helmet';
import { env } from '@config/env';
import { errorHandler } from '@interface/middlewares/errorHandler';
import { authRouter } from '@interface/routes/authRoutes';
import { imovelRouter } from '@interface/routes/imovelRoutes';

export function buildApp(): Application {
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
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.use(`${env.API_PREFIX}/auth`, authRouter);
  app.use(`${env.API_PREFIX}/imoveis`, imovelRouter);

  app.use((_req: Request, res: Response) => {
    res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Rota não encontrada' } });
  });

  app.use(errorHandler);

  return app;
}
