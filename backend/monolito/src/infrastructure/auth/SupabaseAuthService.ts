import {
  AuthSession,
  IAuthService,
  RegisterInput,
} from '@domain/services/IAuthService';
import {
  ConflictError,
  DomainError,
  UnauthorizedError,
} from '@domain/errors/DomainError';
import { supabaseAdmin, supabaseAnon } from '../supabase/supabaseClient';

export class SupabaseAuthService implements IAuthService {
  async register(input: RegisterInput): Promise<{ userId: string; email: string }> {
    // Cria usuário via Admin API com email já confirmado (simplifica fluxo dev/teste).
    // O trigger handle_new_user() popula a tabela profiles automaticamente.
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email: input.email,
      password: input.password,
      email_confirm: true,
      user_metadata: {
        nome: input.nome,
        tipo: input.tipo,
        telefone: input.telefone ?? null,
      },
    });

    if (error) {
      if (error.message.toLowerCase().includes('already')) {
        throw new ConflictError('Email já cadastrado');
      }
      throw new DomainError(`Falha ao registrar usuário: ${error.message}`, 400);
    }

    if (!data.user) {
      throw new DomainError('Falha inesperada ao criar usuário', 500);
    }

    return { userId: data.user.id, email: data.user.email ?? input.email };
  }

  async login(email: string, password: string): Promise<AuthSession> {
    const { data, error } = await supabaseAnon.auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.session || !data.user) {
      throw new UnauthorizedError('Credenciais inválidas');
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresIn: data.session.expires_in,
      userId: data.user.id,
    };
  }

  async verifyToken(token: string): Promise<{ userId: string; email: string }> {
    const { data, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !data.user) {
      throw new UnauthorizedError('Token inválido ou expirado');
    }
    return { userId: data.user.id, email: data.user.email ?? '' };
  }
}
