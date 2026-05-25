import { Profile, TipoUsuario } from '../entities/Profile';

export interface IProfileRepository {
  findById(id: string): Promise<Profile | null>;
  findByEmail(email: string): Promise<Profile | null>;
  upsert(input: {
    id: string;
    nome: string;
    tipo: TipoUsuario;
    telefone?: string | null;
  }): Promise<Profile>;
}
