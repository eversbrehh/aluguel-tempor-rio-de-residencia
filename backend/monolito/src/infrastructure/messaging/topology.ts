import { ConfirmChannel } from 'amqplib';
import { env } from '@config/env';

export const QUEUES = {
  notificacoes: 'notificacoes.eventos',
  tarefas: 'tarefas.eventos',
  chat: 'chat.eventos',
  documentos: 'documentos.eventos',
} as const;

/**
 * Bindings (queue -> routing keys) declarados pelo monolito (publisher).
 * Cada microsserviço consumidor pode redeclarar suas próprias bindings
 * de forma idempotente.
 *
 * Sprint 3:
 * - notificacoes.eventos passa a consumir também eventos emitidos por
 *   MS Tarefa (tarefa.*) e MS Documento (documento.*), para entrega
 *   em tempo real ao app móvel via WebSocket.
 */
const BINDINGS: Record<string, string[]> = {
  [QUEUES.notificacoes]: [
    'associacao.criada',
    'associacao.encerrada',
    'imovel.criado',
    'tarefa.criada',
    'tarefa.concluida',
    'documento.solicitado',
    'documento.enviado',
    'documento.aprovado',
    'documento.rejeitado',
  ],
  [QUEUES.tarefas]: ['associacao.criada', 'associacao.encerrada'],
  [QUEUES.chat]: ['associacao.criada', 'associacao.encerrada'],
  [QUEUES.documentos]: ['associacao.criada'],
};

/**
 * Declara de forma idempotente a topologia AMQP:
 * - Exchange principal (topic, durable)
 * - DLX (topic) + DLQ (durable, bind '#')
 * - Filas dos consumidores ligadas ao exchange principal
 *
 * Todas as filas têm dead-letter-exchange configurado para o DLX.
 */
export async function assertTopology(channel: ConfirmChannel): Promise<void> {
  // Exchange principal
  await channel.assertExchange(env.RABBITMQ_EXCHANGE, 'topic', { durable: true });

  // Dead-Letter Exchange + Dead-Letter Queue
  await channel.assertExchange(env.RABBITMQ_DLX, 'topic', { durable: true });
  await channel.assertQueue(env.RABBITMQ_DLQ, { durable: true });
  await channel.bindQueue(env.RABBITMQ_DLQ, env.RABBITMQ_DLX, '#');

  // Filas dos consumidores
  for (const [queue, routingKeys] of Object.entries(BINDINGS)) {
    await channel.assertQueue(queue, {
      durable: true,
      deadLetterExchange: env.RABBITMQ_DLX,
    });
    for (const rk of routingKeys) {
      await channel.bindQueue(queue, env.RABBITMQ_EXCHANGE, rk);
    }
  }
}
