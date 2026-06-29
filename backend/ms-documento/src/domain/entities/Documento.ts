export type DocumentoStatus = 'solicitado' | 'enviado' | 'aprovado' | 'rejeitado';

export interface Documento {
  id: string;
  associacaoId: string;
  imovelId: string;
  proprietarioId: string;
  comodatarioId: string;
  tipo: string;
  titulo: string;
  status: DocumentoStatus;
  storagePath: string | null;
  observacao: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface DocumentoRow {
  id: string;
  associacao_id: string;
  imovel_id: string;
  proprietario_id: string;
  comodatario_id: string;
  tipo: string;
  titulo: string;
  status: DocumentoStatus;
  storage_path: string | null;
  observacao: string | null;
  created_at: string;
  updated_at: string;
}

export function rowToDocumento(row: DocumentoRow): Documento {
  return {
    id: row.id,
    associacaoId: row.associacao_id,
    imovelId: row.imovel_id,
    proprietarioId: row.proprietario_id,
    comodatarioId: row.comodatario_id,
    tipo: row.tipo,
    titulo: row.titulo,
    status: row.status,
    storagePath: row.storage_path,
    observacao: row.observacao,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
