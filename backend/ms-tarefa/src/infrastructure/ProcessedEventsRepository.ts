import { supabaseAdmin } from '@infrastructure/supabase/SupabaseClient';

export class ProcessedEventsRepository {
  async isProcessed(eventId: string): Promise<boolean> {
    const { data, error } = await supabaseAdmin
      .from('processed_events_tarefa')
      .select('event_id')
      .eq('event_id', eventId)
      .maybeSingle();
    if (error) throw new Error(`Erro ao consultar processed_events: ${error.message}`);
    return data !== null;
  }

  async markProcessed(eventId: string, eventType: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('processed_events_tarefa')
      .insert({ event_id: eventId, event_type: eventType });
    if (error && !/duplicate key/i.test(error.message)) {
      throw new Error(`Erro ao marcar processed_events: ${error.message}`);
    }
  }
}
