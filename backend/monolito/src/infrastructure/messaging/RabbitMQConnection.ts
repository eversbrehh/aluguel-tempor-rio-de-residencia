import amqp, { ChannelModel, ConfirmChannel } from 'amqplib';
import { env } from '@config/env';

/**
 * Singleton para gerenciar a conexão AMQP e o channel de publicação.
 * Implementa reconexão simples com backoff.
 */
class RabbitMQConnection {
  private connection: ChannelModel | null = null;
  private channel: ConfirmChannel | null = null;
  private connecting: Promise<void> | null = null;

  async connect(): Promise<void> {
    if (this.channel) return;
    if (this.connecting) return this.connecting;

    this.connecting = (async () => {
      let attempt = 0;
      const maxAttempts = 10;
      while (attempt < maxAttempts) {
        try {
          attempt += 1;
          const connection = await amqp.connect(env.RABBITMQ_URL);
          const channel = await connection.createConfirmChannel();
          this.connection = connection;
          this.channel = channel;

          connection.on('error', (err: Error) => {
            console.error('[RabbitMQ] connection error:', err.message);
          });
          connection.on('close', () => {
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
      throw new Error('Não foi possível conectar ao RabbitMQ após várias tentativas.');
    })();

    try {
      await this.connecting;
    } finally {
      this.connecting = null;
    }
  }

  getChannel(): ConfirmChannel {
    if (!this.channel) {
      throw new Error('RabbitMQ channel não está disponível. Chame connect() primeiro.');
    }
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
