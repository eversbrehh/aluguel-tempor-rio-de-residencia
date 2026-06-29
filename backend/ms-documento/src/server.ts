import { createServer } from 'http';
import { env } from '@config/env';
import { buildApp } from './app';
import {
  AprovarDocumento,
  CriarSolicitacoesPadrao,
  EnviarDocumento,
  GerarDownloadUrl,
  ListarDocumentos,
  RejeitarDocumento,
  SolicitarDocumento,
} from '@application/useCases/DocumentoUseCases';
import { EventConsumer } from './consumers/EventConsumer';
import { AssociacaoCriadaHandler } from '@handlers/AssociacaoCriadaHandler';
import { AssociacaoEncerradaHandler } from '@handlers/AssociacaoEncerradaHandler';
import { DocumentoController } from '@interface/controllers/DocumentoController';
import { AssociacaoLookup } from '@infrastructure/lookups/AssociacaoLookup';
import {
  assertTopology,
  rabbitMQ,
} from '@infrastructure/messaging/RabbitMQConnection';
import { RabbitMQEventPublisher } from '@infrastructure/messaging/EventPublisher';
import { OutboxRepository } from '@infrastructure/outbox/OutboxRepository';
import { OutboxWorker } from '@infrastructure/outbox/OutboxWorker';
import { ProcessedEventsRepository } from '@infrastructure/ProcessedEventsRepository';
import { DocumentoRepositorySupabase } from '@infrastructure/repositories/DocumentoRepositorySupabase';
import { StorageService } from '@infrastructure/storage/StorageService';

async function bootstrap(): Promise<void> {
  await rabbitMQ.connect();
  const consumeChannel = rabbitMQ.getConsumeChannel();
  await assertTopology(consumeChannel);

  // composição
  const repo = new DocumentoRepositorySupabase();
  const outbox = new OutboxRepository();
  const lookup = new AssociacaoLookup();
  const storage = new StorageService();
  const publisher = new RabbitMQEventPublisher();

  const solicitar = new SolicitarDocumento(repo, outbox, lookup);
  const criarPadrao = new CriarSolicitacoesPadrao(repo, outbox);
  const listar = new ListarDocumentos(repo, lookup);
  const enviar = new EnviarDocumento(repo, outbox, storage);
  const download = new GerarDownloadUrl(repo, storage);
  const aprovar = new AprovarDocumento(repo, outbox);
  const rejeitar = new RejeitarDocumento(repo, outbox);

  const controller = new DocumentoController(
    solicitar,
    listar,
    enviar,
    download,
    aprovar,
    rejeitar,
  );

  // HTTP
  const app = buildApp(controller);
  const httpServer = createServer(app);
  await new Promise<void>((resolve) =>
    httpServer.listen(env.HTTP_PORT, () => {
      console.log(`🌐 [ms-documento] HTTP em http://localhost:${env.HTTP_PORT}`);
      resolve();
    }),
  );

  // outbox worker
  const worker = new OutboxWorker(outbox, publisher);
  worker.start();

  // consumer
  const handlers = [
    new AssociacaoCriadaHandler(criarPadrao),
    new AssociacaoEncerradaHandler(),
  ];
  const processed = new ProcessedEventsRepository();
  const consumer = new EventConsumer(consumeChannel, handlers, processed);
  await consumer.start();
  console.log('📄 MS Documento rodando.');

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
  console.error('❌ Falha ao iniciar MS Documento:', err);
  process.exit(1);
});
