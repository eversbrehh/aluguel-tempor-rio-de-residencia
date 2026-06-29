import { v4 as uuidv4 } from 'uuid';
import { env } from '@config/env';
import { rabbitMQ } from './RabbitMQConnection';

export interface IEventPublisher {
  publish(eventType: string, payload: unknown, eventId?: string): Promise<void>;
}

export class RabbitMQEventPublisher implements IEventPublisher {
  async publish(eventType: string, payload: unknown, eventId?: string): Promise<void> {
    const channel = rabbitMQ.getPublishChannel();

    const envelope = {
      eventId: eventId ?? uuidv4(),
      eventType,
      occurredAt: new Date().toISOString(),
      source: env.EVENT_SOURCE,
      version: 1,
      payload,
    };

    const buffer = Buffer.from(JSON.stringify(envelope), 'utf-8');

    await new Promise<void>((resolve, reject) => {
      const ok = channel.publish(
        env.RABBITMQ_EXCHANGE,
        eventType,
        buffer,
        {
          persistent: true,
          contentType: 'application/json',
          messageId: envelope.eventId,
          timestamp: Date.now(),
          headers: { 'x-event-type': eventType, 'x-source': envelope.source },
        },
        (err) => {
          if (err) reject(err);
          else resolve();
        },
      );
      if (!ok) channel.once('drain', () => resolve());
    });
  }
}
