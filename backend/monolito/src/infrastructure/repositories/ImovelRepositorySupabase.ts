import { Imovel } from '@domain/entities/Imovel';
import {
  CreateImovelInput,
  IImovelRepository,
} from '@domain/repositories/IImovelRepository';
import { supabaseAdmin } from '../supabase/supabaseClient';

interface ImovelRow {
  id: string;
  proprietario_id: string;
  titulo: string;
  endereco: string;
  descricao: string | null;
  valor_aluguel: number | null;
  created_at: string;
  updated_at: string;
}

function toEntity(row: ImovelRow): Imovel {
  return {
    id: row.id,
    proprietarioId: row.proprietario_id,
    titulo: row.titulo,
    endereco: row.endereco,
    descricao: row.descricao,
    valorAluguel: row.valor_aluguel === null ? null : Number(row.valor_aluguel),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class ImovelRepositorySupabase implements IImovelRepository {
  async create(input: CreateImovelInput): Promise<Imovel> {
    const { data, error } = await supabaseAdmin
      .from('imoveis')
      .insert({
        proprietario_id: input.proprietarioId,
        titulo: input.titulo,
        endereco: input.endereco,
        descricao: input.descricao ?? null,
        valor_aluguel: input.valorAluguel ?? null,
      })
      .select()
      .single();

    if (error) throw new Error(`Erro ao criar imóvel: ${error.message}`);
    return toEntity(data as ImovelRow);
  }

  async findById(id: string): Promise<Imovel | null> {
    const { data, error } = await supabaseAdmin
      .from('imoveis')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(`Erro ao buscar imóvel: ${error.message}`);
    return data ? toEntity(data as ImovelRow) : null;
  }

  async findByProprietario(proprietarioId: string): Promise<Imovel[]> {
    const { data, error } = await supabaseAdmin
      .from('imoveis')
      .select('*')
      .eq('proprietario_id', proprietarioId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(`Erro ao listar imóveis: ${error.message}`);
    return (data as ImovelRow[]).map(toEntity);
  }

  async findByComodatarioAtivo(comodatarioId: string): Promise<Imovel[]> {
    // Busca imóveis a partir das associações ativas do comodatário.
    const { data, error } = await supabaseAdmin
      .from('associacoes')
      .select('imoveis:imovel_id(*)')
      .eq('comodatario_id', comodatarioId)
      .eq('status', 'ativa');

    if (error) throw new Error(`Erro ao listar imóveis do comodatário: ${error.message}`);

    // O Supabase pode retornar a relação como objeto único ou array dependendo do schema.
    type JoinRow = { imoveis: ImovelRow | ImovelRow[] | null };
    const rows = (data as unknown as JoinRow[]) ?? [];

    return rows
      .flatMap((r) => (Array.isArray(r.imoveis) ? r.imoveis : r.imoveis ? [r.imoveis] : []))
      .map(toEntity);
  }
}
