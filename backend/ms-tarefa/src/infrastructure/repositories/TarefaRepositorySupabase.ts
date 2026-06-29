import { rowToTarefa, Tarefa, TarefaRow } from '@domain/entities/Tarefa';
import { NotFoundError } from '@domain/errors/DomainError';
import {
  CreateTarefaInput,
  ITarefaRepository,
} from '@domain/repositories/ITarefaRepository';
import { supabaseAdmin } from '@infrastructure/supabase/SupabaseClient';

export class TarefaRepositorySupabase implements ITarefaRepository {
  async create(input: CreateTarefaInput): Promise<Tarefa> {
    const { data, error } = await supabaseAdmin
      .from('tarefas')
      .insert({
        associacao_id: input.associacaoId,
        imovel_id: input.imovelId,
        proprietario_id: input.proprietarioId,
        comodatario_id: input.comodatarioId,
        titulo: input.titulo,
        descricao: input.descricao ?? null,
        recorrencia: input.recorrencia ?? 'unica',
        prazo: input.prazo ?? null,
      })
      .select('*')
      .single();
    if (error || !data) throw new Error(`Erro ao criar tarefa: ${error?.message}`);
    return rowToTarefa(data as TarefaRow);
  }

  async findById(id: string): Promise<Tarefa | null> {
    const { data, error } = await supabaseAdmin
      .from('tarefas')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    if (error) throw new Error(`Erro ao obter tarefa: ${error.message}`);
    return data ? rowToTarefa(data as TarefaRow) : null;
  }

  async listByAssociacao(associacaoId: string): Promise<Tarefa[]> {
    return this.listBy('associacao_id', associacaoId);
  }
  async listByImovel(imovelId: string): Promise<Tarefa[]> {
    return this.listBy('imovel_id', imovelId);
  }
  async listByComodatario(comodatarioId: string): Promise<Tarefa[]> {
    return this.listBy('comodatario_id', comodatarioId);
  }
  async listByProprietario(proprietarioId: string): Promise<Tarefa[]> {
    return this.listBy('proprietario_id', proprietarioId);
  }

  private async listBy(column: string, value: string): Promise<Tarefa[]> {
    const { data, error } = await supabaseAdmin
      .from('tarefas')
      .select('*')
      .eq(column, value)
      .order('created_at', { ascending: false });
    if (error) throw new Error(`Erro ao listar tarefas: ${error.message}`);
    return (data ?? []).map((r) => rowToTarefa(r as TarefaRow));
  }

  async marcarConcluida(id: string): Promise<Tarefa> {
    const { data, error } = await supabaseAdmin
      .from('tarefas')
      .update({ status: 'concluida', concluida_em: new Date().toISOString() })
      .eq('id', id)
      .eq('status', 'pendente')
      .select('*')
      .maybeSingle();
    if (error) throw new Error(`Erro ao concluir tarefa: ${error.message}`);
    if (!data) throw new NotFoundError('Tarefa não encontrada ou não está pendente');
    return rowToTarefa(data as TarefaRow);
  }

  async arquivarPendentesDaAssociacao(associacaoId: string): Promise<number> {
    const { count, error } = await supabaseAdmin
      .from('tarefas')
      .update({ status: 'arquivada' }, { count: 'exact' })
      .eq('associacao_id', associacaoId)
      .eq('status', 'pendente');
    if (error) throw new Error(`Erro ao arquivar tarefas: ${error.message}`);
    return count ?? 0;
  }
}
