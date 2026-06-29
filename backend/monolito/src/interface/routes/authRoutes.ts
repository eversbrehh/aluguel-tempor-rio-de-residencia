import { Router } from 'express';
import { container } from '../container';
import { AuthController } from '../controllers/AuthController';
import { authMiddleware } from '../middlewares/authMiddleware';

export const authRouter = Router();

authRouter.post('/register', AuthController.register);
authRouter.post('/login', AuthController.login);
authRouter.get('/me', authMiddleware(container.authService), AuthController.me);
