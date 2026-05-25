import { TipoUsuario } from '../entities/Profile';

export interface AuthSession {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  userId: string;
}

export interface RegisterInput {
  email: string;
  password: string;
  nome: string;
  tipo: TipoUsuario;
  telefone?: string;
}

export interface IAuthService {
  register(input: RegisterInput): Promise<{ userId: string; email: string }>;
  login(email: string, password: string): Promise<AuthSession>;
  verifyToken(token: string): Promise<{ userId: string; email: string }>;
}
