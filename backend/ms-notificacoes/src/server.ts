import { EventConsumer } from './consumers/EventConsumer';
import { AssociacaoCriadaHandler } from '@handlers/AssociacaoCriadaHandler';
import { AssociacaoEncerradaHandler } from '@handlers/AssociacaoEncerradaHandler';
import { ImovelCriadoHandler } from '@handlers/ImovelCriadoHandler';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { ProcessedEventsRepository } from '@infrastructure/ProcessedEventsRepository';
import { assertConsumerTopology, rabbitMQ } from '@infrastructure/RabbitMQConnection';

async function bootstrap(): Promise<void> {
  await rabbitMQ.connect();
  const channel = rabbitMQ.getChannel();
  await assertConsumerTopology(channel);

  const notificacoes = new NotificacaoRepository();
  const processed = new ProcessedEventsRepository();

  const handlers = [
    new ImovelCriadoHandler(notificacoes),
    new AssociacaoCriadaHandler(notificacoes),
    new AssociacaoEncerradaHandler(notificacoes),
  ];

  const consumer = new EventConsumer(channel, handlers, processed);
  await consumer.start();
  console.log('🔔 MS Notificações rodando.');

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`\n[${signal}] shutting down...`);
    await rabbitMQ.close();
    process.exit(0);
  };
  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

bootstrap().catch((err) => {
  console.error('❌ Falha ao iniciar MS Notificações:', err);
  process.exit(1);
});
