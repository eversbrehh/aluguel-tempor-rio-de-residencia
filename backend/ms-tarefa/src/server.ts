import { createServer } from 'http';
import { env } from '@config/env';
import { buildApp } from './app';
import {
  ArquivarTarefasDaAssociacao,
  ConcluirTarefa,
  CriarTarefa,
  ListarTarefas,
} from '@application/useCases/TarefaUseCases';
import { EventConsumer } from './consumers/EventConsumer';
import { AssociacaoCriadaHandler } from '@handlers/AssociacaoCriadaHandler';
import { AssociacaoEncerradaHandler } from '@handlers/AssociacaoEncerradaHandler';
import { TarefaController } from '@interface/controllers/TarefaController';
import { AssociacaoLookup } from '@infrastructure/lookups/AssociacaoLookup';
import {
  assertTopology,
  rabbitMQ,
} from '@infrastructure/messaging/RabbitMQConnection';
import { RabbitMQEventPublisher } from '@infrastructure/messaging/EventPublisher';
import { OutboxRepository } from '@infrastructure/outbox/OutboxRepository';
import { OutboxWorker } from '@infrastructure/outbox/OutboxWorker';
import { ProcessedEventsRepository } from '@infrastructure/ProcessedEventsRepository';
import { TarefaRepositorySupabase } from '@infrastructure/repositories/TarefaRepositorySupabase';

async function bootstrap(): Promise<void> {
  // 1. Mensageria
  await rabbitMQ.connect();
  const consumeChannel = rabbitMQ.getConsumeChannel();
  await assertTopology(consumeChannel);

  // 2. Composição
  const tarefaRepo = new TarefaRepositorySupabase();
  const outboxRepo = new OutboxRepository();
  const lookup = new AssociacaoLookup();
  const publisher = new RabbitMQEventPublisher();

  const criar = new CriarTarefa(tarefaRepo, outboxRepo, lookup);
  const listar = new ListarTarefas(tarefaRepo, lookup);
  const concluir = new ConcluirTarefa(tarefaRepo, outboxRepo);
  const arquivar = new ArquivarTarefasDaAssociacao(tarefaRepo);

  const controller = new TarefaController(criar, listar, concluir);

  // 3. HTTP
  const app = buildApp(controller);
  const httpServer = createServer(app);
  await new Promise<void>((resolve) =>
    httpServer.listen(env.HTTP_PORT, () => {
      console.log(`🌐 [ms-tarefa] HTTP em http://localhost:${env.HTTP_PORT}`);
      resolve();
    }),
  );

  // 4. Outbox worker
  const worker = new OutboxWorker(outboxRepo, publisher);
  worker.start();

  // 5. Consumer
  const handlers = [
    new AssociacaoCriadaHandler(),
    new AssociacaoEncerradaHandler(arquivar),
  ];
  const processed = new ProcessedEventsRepository();
  const consumer = new EventConsumer(consumeChannel, handlers, processed);
  await consumer.start();
  console.log('🧩 MS Tarefa rodando.');

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`\n[${signal}] shutting down...`);
    await worker.stop();
    httpServer.close();
    await rabbitMQ.close();
    process.exit(0);
  };
  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

bootstrap().catch((err) => {
  console.error('❌ Falha ao iniciar MS Tarefa:', err);
  process.exit(1);
});
