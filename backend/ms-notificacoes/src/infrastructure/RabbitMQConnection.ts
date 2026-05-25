import amqp, { ChannelModel, Channel } from 'amqplib';
import { env } from '@config/env';

class RabbitMQConnection {
  private connection: ChannelModel | null = null;
  private channel: Channel | null = null;

  async connect(): Promise<void> {
    let attempt = 0;
    const maxAttempts = 10;
    while (attempt < maxAttempts) {
      try {
        attempt += 1;
        this.connection = await amqp.connect(env.RABBITMQ_URL);
        this.channel = await this.connection.createChannel();
        await this.channel.prefetch(env.RABBITMQ_PREFETCH);

        this.connection.on('error', (err: Error) => {
          console.error('[RabbitMQ] connection error:', err.message);
        });
        this.connection.on('close', () => {
          console.warn('[RabbitMQ] connection closed.');
          this.connection = null;
          this.channel = null;
        });
        console.log('[RabbitMQ] connected.');
        return;
      } catch (err) {
        const backoff = Math.min(1000 * 2 ** attempt, 15000);
        console.error(
          `[RabbitMQ] connect attempt ${attempt} failed: ${(err as Error).message}. Retrying in ${backoff}ms`,
        );
        await new Promise((r) => setTimeout(r, backoff));
      }
    }
    throw new Error('Não foi possível conectar ao RabbitMQ.');
  }

  getChannel(): Channel {
    if (!this.channel) throw new Error('RabbitMQ channel não disponível.');
    return this.channel;
  }

  async close(): Promise<void> {
    try {
      await this.channel?.close();
    } catch {
      /* ignore */
    }
    try {
      await this.connection?.close();
    } catch {
      /* ignore */
    }
    this.channel = null;
    this.connection = null;
  }
}

export const rabbitMQ = new RabbitMQConnection();

/**
 * Declara de forma idempotente apenas o necessário para este consumidor.
 */
export async function assertConsumerTopology(channel: Channel): Promise<void> {
  await channel.assertExchange(env.RABBITMQ_EXCHANGE, 'topic', { durable: true });
  await channel.assertExchange(env.RABBITMQ_DLX, 'topic', { durable: true });
  await channel.assertQueue(env.RABBITMQ_DLQ, { durable: true });
  await channel.bindQueue(env.RABBITMQ_DLQ, env.RABBITMQ_DLX, '#');
  await channel.assertQueue(env.RABBITMQ_QUEUE, {
    durable: true,
    deadLetterExchange: env.RABBITMQ_DLX,
  });
  await channel.bindQueue(env.RABBITMQ_QUEUE, env.RABBITMQ_EXCHANGE, 'associacao.criada');
  await channel.bindQueue(env.RABBITMQ_QUEUE, env.RABBITMQ_EXCHANGE, 'associacao.encerrada');
  await channel.bindQueue(env.RABBITMQ_QUEUE, env.RABBITMQ_EXCHANGE, 'imovel.criado');
}
