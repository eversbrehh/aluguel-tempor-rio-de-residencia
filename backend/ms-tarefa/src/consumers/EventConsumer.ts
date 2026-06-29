import { Channel, ConsumeMessage } from 'amqplib';
import { env } from '@config/env';
import { eventEnvelopeSchema } from '@domain/EventEnvelope';
import { IEventHandler } from '@handlers/IEventHandler';
import { ProcessedEventsRepository } from '@infrastructure/ProcessedEventsRepository';

export class EventConsumer {
  private readonly handlers: Map<string, IEventHandler>;

  constructor(
    private readonly channel: Channel,
    handlers: IEventHandler[],
    private readonly processedRepo: ProcessedEventsRepository,
  ) {
    this.handlers = new Map(handlers.map((h) => [h.eventType, h]));
  }

  async start(): Promise<void> {
    await this.channel.consume(
      env.RABBITMQ_QUEUE,
      (msg) => {
        if (msg) void this.process(msg);
      },
      { noAck: false },
    );
    console.log(
      `[Consumer] consumindo fila "${env.RABBITMQ_QUEUE}" (eventos: ${[...this.handlers.keys()].join(', ')})`,
    );
  }

  private async process(msg: ConsumeMessage): Promise<void> {
    try {
      const raw = JSON.parse(msg.content.toString('utf-8')) as unknown;
      const parsed = eventEnvelopeSchema.safeParse(raw);
      if (!parsed.success) {
        console.error('[Consumer] envelope inválido — DLQ', parsed.error.flatten());
        this.channel.nack(msg, false, false);
        return;
      }
      const event = parsed.data;

      if (await this.processedRepo.isProcessed(event.eventId)) {
        this.channel.ack(msg);
        return;
      }

      const handler = this.handlers.get(event.eventType);
      if (!handler) {
        console.warn(`[Consumer] sem handler para ${event.eventType} — DLQ`);
        this.channel.nack(msg, false, false);
        return;
      }

      await handler.handle(event);
      await this.processedRepo.markProcessed(event.eventId, event.eventType);
      this.channel.ack(msg);
      console.log(`[Consumer] ok: ${event.eventType} (${event.eventId})`);
    } catch (err) {
      console.error('[Consumer] erro processando mensagem:', (err as Error).message);
      this.channel.nack(msg, false, false);
    }
  }
}
