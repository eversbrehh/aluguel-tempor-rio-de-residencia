import { Router } from 'express';
import { NotificacaoController } from '@interface/controllers/NotificacaoController';
import { authMiddleware } from '@interface/middlewares/authMiddleware';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';

export function buildNotificacaoRouter(repo: NotificacaoRepository): Router {
  const router = Router();
  const controller = new NotificacaoController(repo);

  router.use(authMiddleware);
  router.get('/', (req, res, next) => {
    controller.list(req, res).catch(next);
  });
  router.patch('/lidas', (req, res, next) => {
    controller.markAllAsRead(req, res).catch(next);
  });
  router.patch('/:id/lida', (req, res, next) => {
    controller.markAsRead(req, res).catch(next);
  });

  return router;
}
