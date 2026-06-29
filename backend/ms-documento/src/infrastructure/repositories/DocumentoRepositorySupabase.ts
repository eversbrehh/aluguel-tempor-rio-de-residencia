import {
  Documento,
  DocumentoRow,
  DocumentoStatus,
  rowToDocumento,
} from '@domain/entities/Documento';
import { NotFoundError } from '@domain/errors/DomainError';
import {
  CreateDocumentoInput,
  IDocumentoRepository,
} from '@domain/repositories/IDocumentoRepository';
import { supabaseAdmin } from '@infrastructure/supabase/SupabaseClient';

export class DocumentoRepositorySupabase implements IDocumentoRepository {
  async create(input: CreateDocumentoInput): Promise<Documento> {
    const { data, error } = await supabaseAdmin
      .from('documentos')
      .insert({
        associacao_id: input.associacaoId,
        imovel_id: input.imovelId,
        proprietario_id: input.proprietarioId,
        comodatario_id: input.comodatarioId,
        tipo: input.tipo,
        titulo: input.titulo,
      })
      .select('*')
      .single();
    if (error || !data) throw new Error(`Erro ao criar documento: ${error?.message}`);
    return rowToDocumento(data as DocumentoRow);
  }

  async findById(id: string): Promise<Documento | null> {
    const { data, error } = await supabaseAdmin
      .from('documentos')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    if (error) throw new Error(`Erro ao obter documento: ${error.message}`);
    return data ? rowToDocumento(data as DocumentoRow) : null;
  }

  async listByAssociacao(associacaoId: string): Promise<Documento[]> {
    return this.listBy('associacao_id', associacaoId);
  }
  async listByComodatario(comodatarioId: string): Promise<Documento[]> {
    return this.listBy('comodatario_id', comodatarioId);
  }
  async listByProprietario(proprietarioId: string): Promise<Documento[]> {
    return this.listBy('proprietario_id', proprietarioId);
  }

  private async listBy(column: string, value: string): Promise<Documento[]> {
    const { data, error } = await supabaseAdmin
      .from('documentos')
      .select('*')
      .eq(column, value)
      .order('created_at', { ascending: false });
    if (error) throw new Error(`Erro ao listar documentos: ${error.message}`);
    return (data ?? []).map((r) => rowToDocumento(r as DocumentoRow));
  }

  async updateStatus(
    id: string,
    status: DocumentoStatus,
    extra?: { storagePath?: string | null; observacao?: string | null },
  ): Promise<Documento> {
    const patch: Record<string, unknown> = { status };
    if (extra && 'storagePath' in extra) patch.storage_path = extra.storagePath;
    if (extra && 'observacao' in extra) patch.observacao = extra.observacao;

    const { data, error } = await supabaseAdmin
      .from('documentos')
      .update(patch)
      .eq('id', id)
      .select('*')
      .maybeSingle();
    if (error) throw new Error(`Erro ao atualizar documento: ${error.message}`);
    if (!data) throw new NotFoundError('Documento não encontrado');
    return rowToDocumento(data as DocumentoRow);
  }
}
