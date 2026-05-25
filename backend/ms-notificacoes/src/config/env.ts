import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  RABBITMQ_URL: z.string().min(1),
  RABBITMQ_EXCHANGE: z.string().default('lamd.events'),
  RABBITMQ_QUEUE: z.string().default('notificacoes.eventos'),
  RABBITMQ_DLX: z.string().default('lamd.events.dlx'),
  RABBITMQ_DLQ: z.string().default('lamd.events.dlq'),
  RABBITMQ_PREFETCH: z.coerce.number().int().positive().default(10),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Variáveis de ambiente inválidas (ms-notificacoes):');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
