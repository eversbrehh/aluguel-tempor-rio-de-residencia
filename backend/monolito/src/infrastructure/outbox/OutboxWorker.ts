import { env } from '@config/env';
import { IEventPublisher } from '@infrastructure/messaging/EventPublisher';
import { OutboxRepository } from './OutboxRepository';

/**
 * Worker que faz polling da tabela outbox_events e publica
 * eventos no RabbitMQ. Garante atomicidade na transição
 * "estado de negócio persistido" -> "evento publicado".
 */
export class OutboxWorker {
  private timer: NodeJS.Timeout | null = null;
  private running = false;
  private stopping = false;

  constructor(
    private readonly repository: OutboxRepository,
    private readonly publisher: IEventPublisher,
  ) {}

  start(): void {
    if (this.timer) return;
    console.log(
      `[OutboxWorker] started (interval=${env.OUTBOX_POLL_INTERVAL_MS}ms, batch=${env.OUTBOX_BATCH_SIZE})`,
    );
    this.timer = setInterval(() => this.tick(), env.OUTBOX_POLL_INTERVAL_MS);
  }

  async stop(): Promise<void> {
    this.stopping = true;
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    // aguarda eventual ciclo em andamento
    let waited = 0;
    while (this.running && waited < 5000) {
      await new Promise((r) => setTimeout(r, 100));
      waited += 100;
    }
    console.log('[OutboxWorker] stopped.');
  }

  private async tick(): Promise<void> {
    if (this.running || this.stopping) return;
    this.running = true;
    try {
      const batch = await this.repository.claimBatch(env.OUTBOX_BATCH_SIZE);
      if (batch.length === 0) return;

      for (const row of batch) {
        try {
          await this.publisher.publish(row.event_type, row.payload, row.id);
          await this.repository.markPublished(row.id);
        } catch (err) {
          const msg = (err as Error).message;
          console.error(
            `[OutboxWorker] failed to publish event ${row.id} (${row.event_type}): ${msg}`,
          );
          await this.repository.markFailed(row.id, msg, env.OUTBOX_MAX_ATTEMPTS);
        }
      }
    } catch (err) {
      console.error('[OutboxWorker] tick error:', (err as Error).message);
    } finally {
      this.running = false;
    }
  }
}
