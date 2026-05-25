import { buildApp } from './app';
import { env } from '@config/env';
import { rabbitMQ } from '@infrastructure/messaging/RabbitMQConnection';
import { assertTopology } from '@infrastructure/messaging/topology';
import { RabbitMQEventPublisher } from '@infrastructure/messaging/EventPublisher';
import { OutboxRepository } from '@infrastructure/outbox/OutboxRepository';
import { OutboxWorker } from '@infrastructure/outbox/OutboxWorker';

async function bootstrap(): Promise<void> {
  const app = buildApp();

  // 1. RabbitMQ
  await rabbitMQ.connect();
  await assertTopology(rabbitMQ.getChannel());

  // 2. Outbox Worker
  const outboxWorker = new OutboxWorker(new OutboxRepository(), new RabbitMQEventPublisher());
  outboxWorker.start();

  // 3. HTTP
  const server = app.listen(env.PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`🚀 Monolito LAMD rodando em http://localhost:${env.PORT}${env.API_PREFIX}`);
  });

  // 4. Graceful shutdown
  const shutdown = async (signal: string): Promise<void> => {
    // eslint-disable-next-line no-console
    console.log(`\n[${signal}] shutting down...`);
    server.close();
    await outboxWorker.stop();
    await rabbitMQ.close();
    process.exit(0);
  };
  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('❌ Falha ao iniciar o monolito:', err);
  process.exit(1);
});
