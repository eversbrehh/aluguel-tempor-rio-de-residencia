export interface Imovel {
  id: string;
  proprietarioId: string;
  titulo: string;
  endereco: string;
  descricao?: string | null;
  valorAluguel?: number | null;
  createdAt: string;
  updatedAt: string;
}
