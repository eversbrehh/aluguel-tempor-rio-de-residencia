-- =====================================================================
-- Sprint 2 — Tabelas do MS Notificações
-- =====================================================================
-- Executar no SQL Editor do mesmo projeto Supabase usado pelo monolito.
-- (Coerente com a decisão de padronizar o storage relacional em Supabase.)
-- =====================================================================

-- ---------------------------------------------------------------------
-- TABELA: notificacoes
-- Notificações geradas pelo MS Notificações a partir dos eventos.
-- ---------------------------------------------------------------------
create table if not exists public.notificacoes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  tipo text not null,
  titulo text not null,
  mensagem text not null,
  dados jsonb not null default '{}'::jsonb,
  lida boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notificacoes_usuario_lida_data
  on public.notificacoes(usuario_id, lida, created_at desc);

comment on table public.notificacoes is
  'Notificações persistidas pelo MS Notificações a partir de eventos do RabbitMQ.';

-- ---------------------------------------------------------------------
-- TABELA: processed_events
-- Guarda IDs de eventos já processados para garantir idempotência.
-- ---------------------------------------------------------------------
create table if not exists public.processed_events (
  event_id uuid primary key,
  event_type text not null,
  processed_at timestamptz not null default now()
);

comment on table public.processed_events is
  'Registro de eventos consumidos para garantir idempotência em redeliveries.';

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY (opcional, para acesso futuro pelo app)
-- ---------------------------------------------------------------------
alter table public.notificacoes enable row level security;

drop policy if exists "notificacoes_select_own" on public.notificacoes;
create policy "notificacoes_select_own" on public.notificacoes
  for select using (auth.uid() = usuario_id);

drop policy if exists "notificacoes_update_own" on public.notificacoes;
create policy "notificacoes_update_own" on public.notificacoes
  for update using (auth.uid() = usuario_id);
