import { Associacao, StatusAssociacao } from '@domain/entities/Associacao';
import {
  AssociacaoComNome,
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

interface AssociacaoComJoinRow extends AssociacaoRow {
  comodatario: { nome: string | null } | { nome: string | null }[] | null;
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

function toEntityComNome(row: AssociacaoComJoinRow): AssociacaoComNome {
  const join = row.comodatario;
  const first = Array.isArray(join) ? join[0] : join;
  return {
    ...toEntity(row),
    comodatarioNome: first?.nome ?? null,
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

  async findById(id: string): Promise<Associacao | null> {
    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(`Erro ao buscar associação: ${error.message}`);
    return data ? toEntity(data as AssociacaoRow) : null;
  }

  async findAtivasByImovel(imovelId: string): Promise<AssociacaoComNome[]> {
    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .select('*, comodatario:profiles!comodatario_id(nome)')
      .eq('imovel_id', imovelId)
      .eq('status', 'ativa')
      .order('created_at', { ascending: false });

    if (error) throw new Error(`Erro ao listar associações: ${error.message}`);
    return ((data as unknown as AssociacaoComJoinRow[]) ?? []).map(toEntityComNome);
  }

  async encerrar(id: string, dataFim?: string | null): Promise<Associacao> {
    const update: Record<string, unknown> = { status: 'encerrada' };
    if (dataFim) update.data_fim = dataFim;

    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .update(update)
      .eq('id', id)
      .eq('status', 'ativa')
      .select()
      .maybeSingle();

    if (error) throw new Error(`Erro ao encerrar associação: ${error.message}`);
    if (!data) throw new Error('Associação não encontrada ou já encerrada.');
    return toEntity(data as AssociacaoRow);
  }
}
