import { supabaseAdmin } from '@infrastructure/supabase/SupabaseClient';
import { NotFoundError } from '@domain/errors/DomainError';

export interface AssociacaoLookupResult {
  associacaoId: string;
  imovelId: string;
  proprietarioId: string;
  comodatarioId: string;
  status: 'ativa' | 'encerrada';
}

export class AssociacaoLookup {
  async byId(associacaoId: string): Promise<AssociacaoLookupResult> {
    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .select('id, imovel_id, comodatario_id, status, imoveis ( proprietario_id )')
      .eq('id', associacaoId)
      .maybeSingle();
    if (error) throw new Error(`Erro ao buscar associação: ${error.message}`);
    if (!data) throw new NotFoundError('Associação não encontrada');

    const imoveisField = data.imoveis as unknown;
    const imoveis = Array.isArray(imoveisField)
      ? (imoveisField[0] as { proprietario_id: string } | undefined)
      : (imoveisField as { proprietario_id: string } | null);
    if (!imoveis) throw new NotFoundError('Imóvel da associação não encontrado');

    return {
      associacaoId: data.id as string,
      imovelId: data.imovel_id as string,
      comodatarioId: data.comodatario_id as string,
      proprietarioId: imoveis.proprietario_id,
      status: data.status as 'ativa' | 'encerrada',
    };
  }
}
