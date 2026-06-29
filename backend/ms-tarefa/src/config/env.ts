import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),

  HTTP_PORT: z.coerce.number().int().positive().default(3002),
  API_PREFIX: z.string().default('/api/v1'),
  CORS_ORIGIN: z.string().default('*'),

  RABBITMQ_URL: z.string().min(1),
  RABBITMQ_EXCHANGE: z.string().default('lamd.events'),
  RABBITMQ_QUEUE: z.string().default('tarefas.eventos'),
  RABBITMQ_DLX: z.string().default('lamd.events.dlx'),
  RABBITMQ_DLQ: z.string().default('lamd.events.dlq'),
  RABBITMQ_PREFETCH: z.coerce.number().int().positive().default(10),

  OUTBOX_POLL_INTERVAL_MS: z.coerce.number().int().positive().default(1000),
  OUTBOX_BATCH_SIZE: z.coerce.number().int().positive().default(20),
  OUTBOX_MAX_ATTEMPTS: z.coerce.number().int().positive().default(5),
  EVENT_SOURCE: z.string().default('ms-tarefa'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Variáveis de ambiente inválidas (ms-tarefa):');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
