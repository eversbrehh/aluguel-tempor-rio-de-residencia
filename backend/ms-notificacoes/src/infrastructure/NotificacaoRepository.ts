import { mapRow, Notificacao, NotificacaoRow } from '@domain/Notificacao';
import { WebSocketGateway } from '@infrastructure/websocket/WebSocketGateway';
import { supabaseAdmin } from './SupabaseClient';

export interface CreateNotificacaoInput {
  usuarioId: string;
  tipo: string;
  titulo: string;
  mensagem: string;
  dados?: Record<string, unknown>;
}

export interface ListNotificacoesQuery {
  usuarioId: string;
  onlyUnread?: boolean;
  limit?: number;
  cursor?: string; // created_at ISO
}

export interface ListNotificacoesResult {
  items: Notificacao[];
  nextCursor: string | null;
  unreadCount: number;
}

/**
 * Persiste notificações e, em caso de sucesso, faz push em tempo real
 * via WebSocket para a sala do usuário destinatário.
 */
export class NotificacaoRepository {
  constructor(private readonly gateway?: WebSocketGateway) {}

  async create(input: CreateNotificacaoInput): Promise<Notificacao> {
    const { data, error } = await supabaseAdmin
      .from('notificacoes')
      .insert({
        usuario_id: input.usuarioId,
        tipo: input.tipo,
        titulo: input.titulo,
        mensagem: input.mensagem,
        dados: input.dados ?? {},
      })
      .select('*')
      .single();

    if (error || !data) throw new Error(`Erro ao criar notificação: ${error?.message}`);

    const notificacao = mapRow(data as NotificacaoRow);

    // Best-effort: push em tempo real. Falha de WS nunca derruba o consumer.
    try {
      this.gateway?.emitNova(notificacao.usuarioId, notificacao);
    } catch (err) {
      console.warn('[NotificacaoRepository] falha ao emitir WS:', (err as Error).message);
    }

    return notificacao;
  }

  async list(query: ListNotificacoesQuery): Promise<ListNotificacoesResult> {
    const limit = Math.min(Math.max(query.limit ?? 20, 1), 100);
    let q = supabaseAdmin
      .from('notificacoes')
      .select('*')
      .eq('usuario_id', query.usuarioId)
      .order('created_at', { ascending: false })
      .limit(limit + 1);

    if (query.onlyUnread) q = q.eq('lida', false);
    if (query.cursor) q = q.lt('created_at', query.cursor);

    const { data, error } = await q;
    if (error) throw new Error(`Erro ao listar notificações: ${error.message}`);

    const rows = (data ?? []) as NotificacaoRow[];
    const hasMore = rows.length > limit;
    const trimmed = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? trimmed[trimmed.length - 1].created_at : null;

    const { count, error: countError } = await supabaseAdmin
      .from('notificacoes')
      .select('id', { count: 'exact', head: true })
      .eq('usuario_id', query.usuarioId)
      .eq('lida', false);

    if (countError) throw new Error(`Erro ao contar não lidas: ${countError.message}`);

    return {
      items: trimmed.map(mapRow),
      nextCursor,
      unreadCount: count ?? 0,
    };
  }

  async markAsRead(usuarioId: string, id: string): Promise<Notificacao | null> {
    const { data, error } = await supabaseAdmin
      .from('notificacoes')
      .update({ lida: true })
      .eq('id', id)
      .eq('usuario_id', usuarioId)
      .select('*')
      .maybeSingle();
    if (error) throw new Error(`Erro ao marcar como lida: ${error.message}`);
    return data ? mapRow(data as NotificacaoRow) : null;
  }

  async markAllAsRead(usuarioId: string): Promise<number> {
    const { count, error } = await supabaseAdmin
      .from('notificacoes')
      .update({ lida: true }, { count: 'exact' })
      .eq('usuario_id', usuarioId)
      .eq('lida', false);
    if (error) throw new Error(`Erro ao marcar todas como lidas: ${error.message}`);
    return count ?? 0;
  }
}
