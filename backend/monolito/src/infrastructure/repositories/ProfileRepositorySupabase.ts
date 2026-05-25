import { Profile, TipoUsuario } from '@domain/entities/Profile';
import { IProfileRepository } from '@domain/repositories/IProfileRepository';
import { supabaseAdmin } from '../supabase/supabaseClient';

interface ProfileRow {
  id: string;
  nome: string;
  tipo: TipoUsuario;
  telefone: string | null;
  created_at: string;
}

function toEntity(row: ProfileRow): Profile {
  return {
    id: row.id,
    nome: row.nome,
    tipo: row.tipo,
    telefone: row.telefone,
    createdAt: row.created_at,
  };
}

export class ProfileRepositorySupabase implements IProfileRepository {
  async findById(id: string): Promise<Profile | null> {
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(`Erro ao buscar profile: ${error.message}`);
    return data ? toEntity(data as ProfileRow) : null;
  }

  async findByEmail(email: string): Promise<Profile | null> {
    // O email vive em auth.users; usamos a Admin API para resolver.
    const { data: users, error } = await supabaseAdmin.auth.admin.listUsers();
    if (error) throw new Error(`Erro ao listar usuários: ${error.message}`);

    const user = users.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
    if (!user) return null;

    return this.findById(user.id);
  }

  async upsert(input: {
    id: string;
    nome: string;
    tipo: TipoUsuario;
    telefone?: string | null;
  }): Promise<Profile> {
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .upsert(
        {
          id: input.id,
          nome: input.nome,
          tipo: input.tipo,
          telefone: input.telefone ?? null,
        },
        { onConflict: 'id' },
      )
      .select()
      .single();

    if (error) throw new Error(`Erro ao salvar profile: ${error.message}`);
    return toEntity(data as ProfileRow);
  }
}
