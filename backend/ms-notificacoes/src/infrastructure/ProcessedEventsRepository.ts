import { supabaseAdmin } from './SupabaseClient';

export class ProcessedEventsRepository {
  async isProcessed(eventId: string): Promise<boolean> {
    const { data, error } = await supabaseAdmin
      .from('processed_events')
      .select('event_id')
      .eq('event_id', eventId)
      .maybeSingle();
    if (error) throw new Error(`Erro ao consultar processed_events: ${error.message}`);
    return data !== null;
  }

  async markProcessed(eventId: string, eventType: string): Promise<void> {
    const { error } = await supabaseAdmin
      .from('processed_events')
      .insert({ event_id: eventId, event_type: eventType });
    // Ignora violação de PK (race condition entre workers)
    if (error && !/duplicate key/i.test(error.message)) {
      throw new Error(`Erro ao marcar processed_events: ${error.message}`);
    }
  }
}
