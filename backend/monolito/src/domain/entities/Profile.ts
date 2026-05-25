export type TipoUsuario = 'proprietario' | 'comodatario';

export interface Profile {
  id: string;
  nome: string;
  tipo: TipoUsuario;
  telefone?: string | null;
  createdAt: string;
}
