import { env } from '@config/env';
import { supabaseAdmin } from '@infrastructure/supabase/SupabaseClient';

export interface UploadResult {
  path: string;
}

export class StorageService {
  async upload(
    associacaoId: string,
    documentoId: string,
    fileName: string,
    contentType: string,
    body: Buffer,
  ): Promise<UploadResult> {
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]+/g, '_');
    const path = `associacoes/${associacaoId}/documentos/${documentoId}_${Date.now()}_${safeName}`;
    const { error } = await supabaseAdmin.storage
      .from(env.STORAGE_BUCKET)
      .upload(path, body, { contentType, upsert: true });
    if (error) throw new Error(`Erro ao fazer upload no Storage: ${error.message}`);
    return { path };
  }

  async createSignedUrl(path: string): Promise<string> {
    const { data, error } = await supabaseAdmin.storage
      .from(env.STORAGE_BUCKET)
      .createSignedUrl(path, env.SIGNED_URL_TTL_SECONDS);
    if (error || !data?.signedUrl) {
      throw new Error(`Erro ao gerar signed URL: ${error?.message ?? 'sem url'}`);
    }
    return data.signedUrl;
  }
}
