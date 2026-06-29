import amqp, { ChannelModel, ConfirmChannel, Channel } from 'amqplib';
import { env } from '@config/env';

class RabbitMQConnection {
  private connection: ChannelModel | null = null;
  private publishChannel: ConfirmChannel | null = null;
  private consumeChannel: Channel | null = null;

  async connect(): Promise<void> {
    let attempt = 0;
    const maxAttempts = 10;
    while (attempt < maxAttempts) {
      try {
        attempt += 1;
        this.connection = await amqp.connect(env.RABBITMQ_URL);
        this.publishChannel = await this.connection.createConfirmChannel();
        this.consumeChannel = await this.connection.createChannel();
        await this.consumeChannel.prefetch(env.RABBITMQ_PREFETCH);

        this.connection.on('error', (err: Error) => {
          console.error('[RabbitMQ] connection error:', err.message);
        });
        this.connection.on('close', () => {
          console.warn('[RabbitMQ] connection closed.');
          this.connection = null;
          this.publishChannel = null;
          this.consumeChannel = null;
        });
        console.log('[RabbitMQ] connected (publish + consume channels).');
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

  getPublishChannel(): ConfirmChannel {
    if (!this.publishChannel) throw new Error('RabbitMQ publish channel não disponível.');
    return this.publishChannel;
  }

  getConsumeChannel(): Channel {
    if (!this.consumeChannel) throw new Error('RabbitMQ consume channel não disponível.');
    return this.consumeChannel;
  }

  async close(): Promise<void> {
    try {
      await this.publishChannel?.close();
    } catch {
      /* ignore */
    }
    try {
      await this.consumeChannel?.close();
    } catch {
      /* ignore */
    }
    try {
      await this.connection?.close();
    } catch {
      /* ignore */
    }
    this.publishChannel = null;
    this.consumeChannel = null;
    this.connection = null;
  }
}

export const rabbitMQ = new RabbitMQConnection();

/**
 * Topologia idempotente do MS Tarefa:
 *  - exchange principal (topic) + DLX/DLQ
 *  - fila própria de consumo (tarefas.eventos), bindada a associacao.criada/encerrada
 */
export async function assertTopology(channel: Channel): Promise<void> {
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
}
