import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from '@config/env';
import type { NextFunction, Request, Response } from 'express';

declare module 'express-serve-static-core' {
  interface Request {
    userId?: string;
  }
}

let _supabase: SupabaseClient | null = null;
function getSupabase(): SupabaseClient {
  if (!_supabase) {
    _supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }
  return _supabase;
}

/**
 * Valida o JWT do Supabase enviado no header Authorization: Bearer <token>.
 * Em sucesso, popula req.userId com o auth.users.id.
 */
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const header = req.headers.authorization;
  if (!header || !header.toLowerCase().startsWith('bearer ')) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Token ausente' } });
    return;
  }
  const token = header.slice(7).trim();
  try {
    const { data, error } = await getSupabase().auth.getUser(token);
    if (error || !data?.user) {
      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Token inválido' } });
      return;
    }
    req.userId = data.user.id;
    next();
  } catch (err) {
    res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: (err as Error).message },
    });
  }
}
