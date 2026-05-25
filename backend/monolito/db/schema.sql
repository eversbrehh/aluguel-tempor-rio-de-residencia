-- =====================================================================
-- Schema do banco de dados — Monolito BD (Supabase / PostgreSQL)
-- Sprint 1 — Sistema de Aluguel Temporário de Residência (LAMD)
-- =====================================================================
-- Execute este script no SQL Editor do Supabase.
-- Pré-requisito: extensão pgcrypto (já habilitada por padrão no Supabase).
-- =====================================================================

-- ---------------------------------------------------------------------
-- TABELA: profiles
-- Estende auth.users do Supabase com dados do domínio.
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  tipo text not null check (tipo in ('proprietario', 'comodatario')),
  telefone text,
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'Perfil de domínio associado 1:1 ao usuário do Supabase Auth.';

-- ---------------------------------------------------------------------
-- TABELA: imoveis
-- Cadastro de imóveis pertencentes a um proprietário.
-- ---------------------------------------------------------------------
create table if not exists public.imoveis (
  id uuid primary key default gen_random_uuid(),
  proprietario_id uuid not null references public.profiles(id) on delete cascade,
  titulo text not null,
  endereco text not null,
  descricao text,
  valor_aluguel numeric(10, 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_imoveis_proprietario on public.imoveis(proprietario_id);

-- Trigger para atualizar updated_at automaticamente
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_imoveis_updated_at on public.imoveis;
create trigger trg_imoveis_updated_at
  before update on public.imoveis
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- TABELA: associacoes
-- Vincula um comodatário a um imóvel com período de estadia.
-- ---------------------------------------------------------------------
create table if not exists public.associacoes (
  id uuid primary key default gen_random_uuid(),
  imovel_id uuid not null references public.imoveis(id) on delete cascade,
  comodatario_id uuid not null references public.profiles(id) on delete cascade,
  data_inicio date not null,
  data_fim date,
  status text not null default 'ativa' check (status in ('ativa', 'encerrada')),
  created_at timestamptz not null default now()
);

create index if not exists idx_associacoes_imovel on public.associacoes(imovel_id);
create index if not exists idx_associacoes_comodatario on public.associacoes(comodatario_id);

-- Apenas uma associação ATIVA por par (imóvel, comodatário)
create unique index if not exists uq_associacao_ativa
  on public.associacoes(imovel_id, comodatario_id)
  where status = 'ativa';

-- ---------------------------------------------------------------------
-- TRIGGER: cria automaticamente o profile ao registrar um auth.user
-- O backend envia os metadados (nome, tipo) no signUp.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nome, tipo, telefone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', new.email),
    coalesce(new.raw_user_meta_data ->> 'tipo', 'comodatario'),
    new.raw_user_meta_data ->> 'telefone'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
-- Observação: o backend usa a SERVICE_ROLE_KEY que bypassa RLS.
-- As policies abaixo protegem os dados caso, no futuro, o frontend
-- acesse o Supabase diretamente.
-- =====================================================================

alter table public.profiles enable row level security;
alter table public.imoveis enable row level security;
alter table public.associacoes enable row level security;

-- profiles: cada usuário lê e atualiza apenas o próprio perfil
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- imoveis: proprietário gerencia os seus; comodatário lê apenas onde está associado
drop policy if exists "imoveis_select_proprietario_ou_associado" on public.imoveis;
create policy "imoveis_select_proprietario_ou_associado" on public.imoveis
  for select using (
    proprietario_id = auth.uid()
    or exists (
      select 1 from public.associacoes a
      where a.imovel_id = imoveis.id
        and a.comodatario_id = auth.uid()
        and a.status = 'ativa'
    )
  );

drop policy if exists "imoveis_insert_proprietario" on public.imoveis;
create policy "imoveis_insert_proprietario" on public.imoveis
  for insert with check (proprietario_id = auth.uid());

drop policy if exists "imoveis_update_proprietario" on public.imoveis;
create policy "imoveis_update_proprietario" on public.imoveis
  for update using (proprietario_id = auth.uid());

drop policy if exists "imoveis_delete_proprietario" on public.imoveis;
create policy "imoveis_delete_proprietario" on public.imoveis
  for delete using (proprietario_id = auth.uid());

-- associacoes: visíveis para proprietário do imóvel e para o comodatário envolvido
drop policy if exists "associacoes_select_envolvidos" on public.associacoes;
create policy "associacoes_select_envolvidos" on public.associacoes
  for select using (
    comodatario_id = auth.uid()
    or exists (
      select 1 from public.imoveis i
      where i.id = associacoes.imovel_id and i.proprietario_id = auth.uid()
    )
  );

drop policy if exists "associacoes_insert_proprietario" on public.associacoes;
create policy "associacoes_insert_proprietario" on public.associacoes
  for insert with check (
    exists (
      select 1 from public.imoveis i
      where i.id = imovel_id and i.proprietario_id = auth.uid()
    )
  );
