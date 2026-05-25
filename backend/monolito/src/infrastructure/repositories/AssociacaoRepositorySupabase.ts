import { Associacao, StatusAssociacao } from '@domain/entities/Associacao';
import {
  CreateAssociacaoInput,
  IAssociacaoRepository,
} from '@domain/repositories/IAssociacaoRepository';
import { supabaseAdmin } from '../supabase/supabaseClient';

interface AssociacaoRow {
  id: string;
  imovel_id: string;
  comodatario_id: string;
  data_inicio: string;
  data_fim: string | null;
  status: StatusAssociacao;
  created_at: string;
}

function toEntity(row: AssociacaoRow): Associacao {
  return {
    id: row.id,
    imovelId: row.imovel_id,
    comodatarioId: row.comodatario_id,
    dataInicio: row.data_inicio,
    dataFim: row.data_fim,
    status: row.status,
    createdAt: row.created_at,
  };
}

export class AssociacaoRepositorySupabase implements IAssociacaoRepository {
  async create(input: CreateAssociacaoInput): Promise<Associacao> {
    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .insert({
        imovel_id: input.imovelId,
        comodatario_id: input.comodatarioId,
        data_inicio: input.dataInicio,
        data_fim: input.dataFim ?? null,
        status: 'ativa',
      })
      .select()
      .single();

    if (error) throw new Error(`Erro ao criar associação: ${error.message}`);
    return toEntity(data as AssociacaoRow);
  }

  async findAtivaByImovelEComodatario(
    imovelId: string,
    comodatarioId: string,
  ): Promise<Associacao | null> {
    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .select('*')
      .eq('imovel_id', imovelId)
      .eq('comodatario_id', comodatarioId)
      .eq('status', 'ativa')
      .maybeSingle();

    if (error) throw new Error(`Erro ao buscar associação: ${error.message}`);
    return data ? toEntity(data as AssociacaoRow) : null;
  }
}
