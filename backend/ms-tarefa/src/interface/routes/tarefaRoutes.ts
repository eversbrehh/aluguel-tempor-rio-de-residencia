import { Router } from 'express';
import { TarefaController } from '@interface/controllers/TarefaController';
import { authMiddleware } from '@interface/middlewares/authMiddleware';

export function buildTarefaRouter(controller: TarefaController): Router {
  const router = Router();
  router.use(authMiddleware);
  router.post('/', (req, res, next) => {
    controller.create(req, res).catch(next);
  });
  router.get('/', (req, res, next) => {
    controller.list(req, res).catch(next);
  });
  router.patch('/:id/concluir', (req, res, next) => {
    controller.concluirById(req, res).catch(next);
  });
  return router;
}
