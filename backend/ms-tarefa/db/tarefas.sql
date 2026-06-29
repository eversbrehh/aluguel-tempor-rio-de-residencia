-- =====================================================================
-- MS Tarefa — schema (Supabase / PostgreSQL)
-- Sprint 3 — Sistema de Aluguel Temporário de Residência (LAMD)
-- =====================================================================
-- Executar no SQL Editor do MESMO projeto Supabase usado pelo monolito,
-- após schema.sql e sprint2-outbox.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TABELA: tarefas
-- ---------------------------------------------------------------------
create table if not exists public.tarefas (
  id uuid primary key default gen_random_uuid(),
  associacao_id uuid not null,
  imovel_id uuid not null,
  proprietario_id uuid not null references public.profiles(id) on delete cascade,
  comodatario_id uuid not null references public.profiles(id) on delete cascade,
  titulo text not null,
  descricao text,
  recorrencia text not null default 'unica'
    check (recorrencia in ('unica','diaria','semanal','mensal')),
  prazo date,
  status text not null default 'pendente'
    check (status in ('pendente','concluida','arquivada')),
  concluida_em timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_tarefas_associacao on public.tarefas(associacao_id);
create index if not exists idx_tarefas_imovel on public.tarefas(imovel_id);
create index if not exists idx_tarefas_comodatario_status
  on public.tarefas(comodatario_id, status);

comment on table public.tarefas is
  'Tarefas atribuídas a um comodatário no contexto de uma associação.';

-- ---------------------------------------------------------------------
-- OUTBOX próprio do MS Tarefa
-- ---------------------------------------------------------------------
create table if not exists public.tarefa_outbox_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  aggregate_id uuid,
  payload jsonb not null,
  status text not null default 'pending'
    check (status in ('pending', 'published', 'failed')),
  attempts int not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  published_at timestamptz
);

create index if not exists idx_tarefa_outbox_status_created
  on public.tarefa_outbox_events(status, created_at)
  where status = 'pending';

create or replace function public.claim_tarefa_outbox_batch(batch_size int default 50)
returns setof public.tarefa_outbox_events
language plpgsql
as $$
begin
  return query
  with claimed as (
    select id
    from public.tarefa_outbox_events
    where status = 'pending'
    order by created_at
    limit batch_size
    for update skip locked
  )
  update public.tarefa_outbox_events oe
  set attempts = oe.attempts + 1
  from claimed
  where oe.id = claimed.id
  returning oe.*;
end;
$$;

create or replace function public.mark_tarefa_outbox_published(p_event_id uuid)
returns void
language sql
as $$
  update public.tarefa_outbox_events
  set status = 'published',
      published_at = now(),
      last_error = null
  where id = p_event_id;
$$;

create or replace function public.mark_tarefa_outbox_failed(
  p_event_id uuid,
  p_error text,
  p_max_attempts int default 5
)
returns void
language plpgsql
as $$
begin
  update public.tarefa_outbox_events
  set status = case
                 when attempts >= p_max_attempts then 'failed'
                 else 'pending'
               end,
      last_error = p_error
  where id = p_event_id;
end;
$$;

-- ---------------------------------------------------------------------
-- TABELA: processed_events_tarefa (idempotência do consumer)
-- ---------------------------------------------------------------------
create table if not exists public.processed_events_tarefa (
  event_id uuid primary key,
  event_type text not null,
  processed_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY (consumido pelo MS via service role -> bypass).
-- Policies protegem caso o app acesse o Supabase diretamente.
-- ---------------------------------------------------------------------
alter table public.tarefas enable row level security;

drop policy if exists "tarefas_select_envolvidos" on public.tarefas;
create policy "tarefas_select_envolvidos" on public.tarefas
  for select using (
    auth.uid() = comodatario_id or auth.uid() = proprietario_id
  );
