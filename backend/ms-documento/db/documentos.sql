-- =====================================================================
-- MS Documento — schema (Supabase / PostgreSQL + Supabase Storage)
-- Sprint 3 — Sistema de Aluguel Temporário de Residência (LAMD)
-- =====================================================================
-- Executar no SQL Editor do MESMO projeto Supabase usado pelo monolito,
-- após schema.sql e sprint2-outbox.sql.
--
-- Pré-requisito Storage: criar (uma vez) um bucket PRIVADO chamado
-- `documentos` em Storage > New bucket.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TABELA: documentos
-- ---------------------------------------------------------------------
create table if not exists public.documentos (
  id uuid primary key default gen_random_uuid(),
  associacao_id uuid not null,
  imovel_id uuid not null,
  proprietario_id uuid not null references public.profiles(id) on delete cascade,
  comodatario_id uuid not null references public.profiles(id) on delete cascade,
  tipo text not null,
  titulo text not null,
  status text not null default 'solicitado'
    check (status in ('solicitado','enviado','aprovado','rejeitado')),
  storage_path text,
  observacao text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_documentos_associacao on public.documentos(associacao_id);
create index if not exists idx_documentos_comodatario_status
  on public.documentos(comodatario_id, status);

-- updated_at trigger
create or replace function public.documentos_set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_documentos_updated_at on public.documentos;
create trigger trg_documentos_updated_at
  before update on public.documentos
  for each row execute function public.documentos_set_updated_at();

comment on table public.documentos is
  'Documentos solicitados pelo proprietário e enviados pelo comodatário (storage no bucket "documentos").';

-- ---------------------------------------------------------------------
-- OUTBOX próprio do MS Documento
-- ---------------------------------------------------------------------
create table if not exists public.documento_outbox_events (
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

create index if not exists idx_documento_outbox_status_created
  on public.documento_outbox_events(status, created_at)
  where status = 'pending';

create or replace function public.claim_documento_outbox_batch(batch_size int default 50)
returns setof public.documento_outbox_events
language plpgsql
as $$
begin
  return query
  with claimed as (
    select id
    from public.documento_outbox_events
    where status = 'pending'
    order by created_at
    limit batch_size
    for update skip locked
  )
  update public.documento_outbox_events oe
  set attempts = oe.attempts + 1
  from claimed
  where oe.id = claimed.id
  returning oe.*;
end;
$$;

create or replace function public.mark_documento_outbox_published(p_event_id uuid)
returns void
language sql
as $$
  update public.documento_outbox_events
  set status = 'published',
      published_at = now(),
      last_error = null
  where id = p_event_id;
$$;

create or replace function public.mark_documento_outbox_failed(
  p_event_id uuid,
  p_error text,
  p_max_attempts int default 5
)
returns void
language plpgsql
as $$
begin
  update public.documento_outbox_events
  set status = case
                 when attempts >= p_max_attempts then 'failed'
                 else 'pending'
               end,
      last_error = p_error
  where id = p_event_id;
end;
$$;

-- ---------------------------------------------------------------------
-- TABELA: processed_events_documento (idempotência do consumer)
-- ---------------------------------------------------------------------
create table if not exists public.processed_events_documento (
  event_id uuid primary key,
  event_type text not null,
  processed_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY (service role bypass)
-- ---------------------------------------------------------------------
alter table public.documentos enable row level security;

drop policy if exists "documentos_select_envolvidos" on public.documentos;
create policy "documentos_select_envolvidos" on public.documentos
  for select using (
    auth.uid() = comodatario_id or auth.uid() = proprietario_id
  );
