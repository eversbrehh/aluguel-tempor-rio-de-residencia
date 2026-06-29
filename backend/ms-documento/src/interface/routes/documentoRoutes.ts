import { Router } from 'express';
import multer from 'multer';
import { env } from '@config/env';
import { DocumentoController } from '@interface/controllers/DocumentoController';
import { authMiddleware } from '@interface/middlewares/authMiddleware';

export function buildDocumentoRouter(controller: DocumentoController): Router {
  const router = Router();
  const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: env.UPLOAD_MAX_BYTES },
  });

  router.use(authMiddleware);
  router.post('/', (req, res, next) => controller.create(req, res).catch(next));
  router.get('/', (req, res, next) => controller.list(req, res).catch(next));
  router.post('/:id/upload', upload.single('file'), (req, res, next) =>
    controller.upload(req, res).catch(next),
  );
  router.get('/:id/download', (req, res, next) =>
    controller.download(req, res).catch(next),
  );
  router.patch('/:id/aprovar', (req, res, next) =>
    controller.approve(req, res).catch(next),
  );
  router.patch('/:id/rejeitar', (req, res, next) =>
    controller.reject(req, res).catch(next),
  );

  return router;
}
