import { Router } from 'express';
import { container } from '../container';
import { ImovelController } from '../controllers/ImovelController';
import { authMiddleware } from '../middlewares/authMiddleware';

export const imovelRouter = Router();

imovelRouter.use(authMiddleware(container.authService));

imovelRouter.post('/', ImovelController.create);
imovelRouter.get('/meus', ImovelController.listMine);
imovelRouter.get('/:id', ImovelController.getById);
imovelRouter.post('/:id/associacoes', ImovelController.associarComodatario);
