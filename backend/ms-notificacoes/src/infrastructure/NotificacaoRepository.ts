import { supabaseAdmin } from './SupabaseClient';

export interface CreateNotificacaoInput {
  usuarioId: string;
  tipo: string;
  titulo: string;
  mensagem: string;
  dados?: Record<string, unknown>;
}

export class NotificacaoRepository {
  async create(input: CreateNotificacaoInput): Promise<void> {
    const { error } = await supabaseAdmin.from('notificacoes').insert({
      usuario_id: input.usuarioId,
      tipo: input.tipo,
      titulo: input.titulo,
      mensagem: input.mensagem,
      dados: input.dados ?? {},
    });
    if (error) throw new Error(`Erro ao criar notificação: ${error.message}`);
  }
}
