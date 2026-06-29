import { createServer } from 'http';
import { env } from '@config/env';
import { buildApp } from './app';
import { EventConsumer } from './consumers/EventConsumer';
import { AssociacaoCriadaHandler } from '@handlers/AssociacaoCriadaHandler';
import { AssociacaoEncerradaHandler } from '@handlers/AssociacaoEncerradaHandler';
import { DocumentoAprovadoHandler } from '@handlers/DocumentoAprovadoHandler';
import { DocumentoEnviadoHandler } from '@handlers/DocumentoEnviadoHandler';
import { DocumentoRejeitadoHandler } from '@handlers/DocumentoRejeitadoHandler';
import { DocumentoSolicitadoHandler } from '@handlers/DocumentoSolicitadoHandler';
import { ImovelCriadoHandler } from '@handlers/ImovelCriadoHandler';
import { TarefaConcluidaHandler } from '@handlers/TarefaConcluidaHandler';
import { TarefaCriadaHandler } from '@handlers/TarefaCriadaHandler';
import { NotificacaoRepository } from '@infrastructure/NotificacaoRepository';
import { ProcessedEventsRepository } from '@infrastructure/ProcessedEventsRepository';
import { assertConsumerTopology, rabbitMQ } from '@infrastructure/RabbitMQConnection';
import { WebSocketGateway } from '@infrastructure/websocket/WebSocketGateway';

async function bootstrap(): Promise<void> {
  // 1. Mensageria
  await rabbitMQ.connect();
  const channel = rabbitMQ.getChannel();
  await assertConsumerTopology(channel);

  // 2. WebSocket gateway (anexado ao servidor HTTP do Express)
  const gateway = new WebSocketGateway();
  const notificacoes = new NotificacaoRepository(gateway);
  const processed = new ProcessedEventsRepository();

  // 3. HTTP REST
  const app = buildApp(notificacoes);
  const httpServer = createServer(app);
  gateway.attach(httpServer);

  await new Promise<void>((resolve) => {
    httpServer.listen(env.HTTP_PORT, () => {
      console.log(`🌐 [ms-notificacoes] HTTP+WS em http://localhost:${env.HTTP_PORT}`);
      resolve();
    });
  });

  // 4. Consumer
  const handlers = [
    new ImovelCriadoHandler(notificacoes),
    new AssociacaoCriadaHandler(notificacoes),
    new AssociacaoEncerradaHandler(notificacoes),
    new TarefaCriadaHandler(notificacoes),
    new TarefaConcluidaHandler(notificacoes),
    new DocumentoSolicitadoHandler(notificacoes),
    new DocumentoEnviadoHandler(notificacoes),
    new DocumentoAprovadoHandler(notificacoes),
    new DocumentoRejeitadoHandler(notificacoes),
  ];
  const consumer = new EventConsumer(channel, handlers, processed);
  await consumer.start();
  console.log('🔔 MS Notificações rodando.');

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`\n[${signal}] shutting down...`);
    try {
      await gateway.close();
    } catch {
      /* ignore */
    }
    httpServer.close();
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
