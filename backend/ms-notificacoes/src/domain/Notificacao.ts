export interface Notificacao {
  id: string;
  usuarioId: string;
  tipo: string;
  titulo: string;
  mensagem: string;
  dados: Record<string, unknown>;
  lida: boolean;
  createdAt: string;
}

export interface NotificacaoRow {
  id: string;
  usuario_id: string;
  tipo: string;
  titulo: string;
  mensagem: string;
  dados: Record<string, unknown>;
  lida: boolean;
  created_at: string;
}

export function mapRow(row: NotificacaoRow): Notificacao {
  return {
    id: row.id,
    usuarioId: row.usuario_id,
    tipo: row.tipo,
    titulo: row.titulo,
    mensagem: row.mensagem,
    dados: row.dados ?? {},
    lida: row.lida,
    createdAt: row.created_at,
  };
}
