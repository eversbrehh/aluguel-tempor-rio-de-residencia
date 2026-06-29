import { supabaseAdmin } from '@infrastructure/supabase/SupabaseClient';

export interface OutboxEventRow {
  id: string;
  event_type: string;
  aggregate_id: string | null;
  payload: Record<string, unknown>;
  status: 'pending' | 'published' | 'failed';
  attempts: number;
  last_error: string | null;
  created_at: string;
  published_at: string | null;
}

export class OutboxRepository {
  async insert(eventType: string, payload: Record<string, unknown>, aggregateId?: string): Promise<void> {
    const { error } = await supabaseAdmin.from('tarefa_outbox_events').insert({
      event_type: eventType,
      aggregate_id: aggregateId ?? null,
      payload,
    });
    if (error) throw new Error(`Erro ao gravar outbox: ${error.message}`);
  }

  async claimBatch(batchSize: number): Promise<OutboxEventRow[]> {
    const { data, error } = await supabaseAdmin.rpc('claim_tarefa_outbox_batch', {
      batch_size: batchSize,
    });
    if (error) throw new Error(`claim_tarefa_outbox_batch failed: ${error.message}`);
    return (data ?? []) as OutboxEventRow[];
  }

  async markPublished(eventId: string): Promise<void> {
    const { error } = await supabaseAdmin.rpc('mark_tarefa_outbox_published', {
      p_event_id: eventId,
    });
    if (error) throw new Error(`mark_tarefa_outbox_published failed: ${error.message}`);
  }

  async markFailed(eventId: string, errorMessage: string, maxAttempts: number): Promise<void> {
    const { error } = await supabaseAdmin.rpc('mark_tarefa_outbox_failed', {
      p_event_id: eventId,
      p_error: errorMessage,
      p_max_attempts: maxAttempts,
    });
    if (error) throw new Error(`mark_tarefa_outbox_failed failed: ${error.message}`);
  }
}
