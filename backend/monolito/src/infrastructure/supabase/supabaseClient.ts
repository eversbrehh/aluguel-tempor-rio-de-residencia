import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from '@config/env';

/**
 * Client com SERVICE_ROLE_KEY: bypassa RLS.
 * Use no backend para operações administrativas / consultas internas.
 */
export const supabaseAdmin: SupabaseClient = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);

/**
 * Client público com ANON_KEY. Usado para operações de auth (signUp/signIn)
 * que precisam respeitar políticas públicas do projeto Supabase.
 */
export const supabaseAnon: SupabaseClient = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_ANON_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);
