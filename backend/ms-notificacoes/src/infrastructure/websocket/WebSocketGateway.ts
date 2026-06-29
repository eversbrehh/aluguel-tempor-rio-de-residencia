import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from '@config/env';
import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { Notificacao } from '@domain/Notificacao';

/**
 * Gateway WebSocket: cada cliente autentica enviando o accessToken do Supabase
 * no handshake (`auth.token` ou header Authorization). Após validar, o socket
 * entra na sala `user:<userId>` para receber pushes direcionados.
 *
 * Eventos emitidos para o cliente:
 *   - "notificacao:nova"   payload: Notificacao
 */
export class WebSocketGateway {
  private io: Server | null = null;
  private readonly supabase: SupabaseClient;

  constructor() {
    this.supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }

  attach(server: HttpServer): void {
    const corsOrigin =
      env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',').map((o) => o.trim());

    this.io = new Server(server, {
      cors: { origin: corsOrigin, credentials: true },
      path: '/socket.io',
    });

    this.io.use(async (socket: Socket, next) => {
      try {
        const token = this.extractToken(socket);
        if (!token) return next(new Error('UNAUTHORIZED'));

        const { data, error } = await this.supabase.auth.getUser(token);
        if (error || !data?.user) return next(new Error('UNAUTHORIZED'));

        socket.data.userId = data.user.id;
        return next();
      } catch (err) {
        return next(new Error('UNAUTHORIZED'));
      }
    });

    this.io.on('connection', (socket: Socket) => {
      const userId = socket.data.userId as string;
      void socket.join(`user:${userId}`);
      console.log(`[WS] user ${userId} connected (${socket.id})`);

      socket.on('disconnect', (reason) => {
        console.log(`[WS] user ${userId} disconnected (${reason})`);
      });
    });

    console.log('[WS] socket.io gateway attached at /socket.io');
  }

  emitNova(usuarioId: string, notificacao: Notificacao): void {
    this.io?.to(`user:${usuarioId}`).emit('notificacao:nova', notificacao);
  }

  async close(): Promise<void> {
    await new Promise<void>((resolve) => {
      if (!this.io) return resolve();
      this.io.close(() => resolve());
    });
    this.io = null;
  }

  private extractToken(socket: Socket): string | null {
    const auth = socket.handshake.auth as { token?: string } | undefined;
    if (auth?.token) return auth.token;
    const header =
      socket.handshake.headers.authorization ?? socket.handshake.headers.Authorization;
    if (typeof header === 'string' && header.toLowerCase().startsWith('bearer ')) {
      return header.slice(7).trim();
    }
    return null;
  }
}
