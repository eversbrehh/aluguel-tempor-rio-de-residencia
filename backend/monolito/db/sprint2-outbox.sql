-- =====================================================================
-- Sprint 2 — Outbox Pattern + Triggers de eventos de domínio
-- Sistema de Aluguel Temporário de Residência (LAMD)
-- =====================================================================
-- Pré-requisito: schema.sql da Sprint 1 já executado.
-- Execute este script no SQL Editor do Supabase APÓS o schema.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TABELA: outbox_events
-- Persistência local de eventos a serem publicados no RabbitMQ.
-- Garante atomicidade entre mudança de estado de negócio e publicação.
-- ---------------------------------------------------------------------
create table if not exists public.outbox_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  aggregate_id uuid,
  payload jsonb not null,
  status text not null default 'pending' check (status in ('pending', 'published', 'failed')),
  attempts int not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  published_at timestamptz
);

create index if not exists idx_outbox_status_created
  on public.outbox_events(status, created_at)
  where status = 'pending';

comment on table public.outbox_events is
  'Outbox para publicação assíncrona de eventos de domínio no RabbitMQ.';

-- ---------------------------------------------------------------------
-- FUNÇÃO: claim_outbox_batch
-- Reserva um lote de eventos pendentes para publicação.
-- Usa SELECT FOR UPDATE SKIP LOCKED para suportar múltiplos workers.
-- ---------------------------------------------------------------------
create or replace function public.claim_outbox_batch(batch_size int default 50)
returns setof public.outbox_events
language plpgsql
as $$
begin
  return query
  with claimed as (
    select id
    from public.outbox_events
    where status = 'pending'
    order by created_at
    limit batch_size
    for update skip locked
  )
  update public.outbox_events oe
  set attempts = oe.attempts + 1
  from claimed
  where oe.id = claimed.id
  returning oe.*;
end;
$$;

-- ---------------------------------------------------------------------
-- FUNÇÃO: mark_outbox_published
-- ---------------------------------------------------------------------
create or replace function public.mark_outbox_published(p_event_id uuid)
returns void
language sql
as $$
  update public.outbox_events
  set status = 'published',
      published_at = now(),
      last_error = null
  where id = p_event_id;
$$;

-- ---------------------------------------------------------------------
-- FUNÇÃO: mark_outbox_failed
-- Marca como 'failed' apenas se ultrapassou max_attempts;
-- caso contrário mantém 'pending' para retry no próximo ciclo.
-- ---------------------------------------------------------------------
create or replace function public.mark_outbox_failed(
  p_event_id uuid,
  p_error text,
  p_max_attempts int default 5
)
returns void
language plpgsql
as $$
begin
  update public.outbox_events
  set status = case
                 when attempts >= p_max_attempts then 'failed'
                 else 'pending'
               end,
      last_error = p_error
  where id = p_event_id;
end;
$$;

-- =====================================================================
-- TRIGGERS DE EVENTOS DE DOMÍNIO
-- =====================================================================

-- ---------------------------------------------------------------------
-- TRIGGER: imovel.criado
-- ---------------------------------------------------------------------
create or replace function public.trg_imoveis_after_insert()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.outbox_events (event_type, aggregate_id, payload)
  values (
    'imovel.criado',
    new.id,
    jsonb_build_object(
      'imovelId', new.id,
      'proprietarioId', new.proprietario_id,
      'titulo', new.titulo,
      'endereco', new.endereco,
      'valorAluguel', new.valor_aluguel,
      'criadoEm', new.created_at
    )
  );
  return new;
end;
$$;

drop trigger if exists imoveis_after_insert on public.imoveis;
create trigger imoveis_after_insert
  after insert on public.imoveis
  for each row execute function public.trg_imoveis_after_insert();

-- ---------------------------------------------------------------------
-- TRIGGER: associacao.criada
-- ---------------------------------------------------------------------
create or replace function public.trg_associacoes_after_insert()
returns trigger
language plpgsql
security definer
as $$
declare
  v_proprietario_id uuid;
begin
  select proprietario_id into v_proprietario_id
  from public.imoveis
  where id = new.imovel_id;

  insert into public.outbox_events (event_type, aggregate_id, payload)
  values (
    'associacao.criada',
    new.id,
    jsonb_build_object(
      'associacaoId', new.id,
      'imovelId', new.imovel_id,
      'comodatarioId', new.comodatario_id,
      'proprietarioId', v_proprietario_id,
      'dataInicio', new.data_inicio,
      'dataFim', new.data_fim,
      'criadoEm', new.created_at
    )
  );
  return new;
end;
$$;

drop trigger if exists associacoes_after_insert on public.associacoes;
create trigger associacoes_after_insert
  after insert on public.associacoes
  for each row execute function public.trg_associacoes_after_insert();

-- ---------------------------------------------------------------------
-- TRIGGER: associacao.encerrada
-- Dispara apenas quando o status muda de 'ativa' para 'encerrada'.
-- ---------------------------------------------------------------------
create or replace function public.trg_associacoes_after_update_status()
returns trigger
language plpgsql
security definer
as $$
declare
  v_proprietario_id uuid;
begin
  if old.status = 'ativa' and new.status = 'encerrada' then
    select proprietario_id into v_proprietario_id
    from public.imoveis
    where id = new.imovel_id;

    insert into public.outbox_events (event_type, aggregate_id, payload)
    values (
      'associacao.encerrada',
      new.id,
      jsonb_build_object(
        'associacaoId', new.id,
        'imovelId', new.imovel_id,
        'comodatarioId', new.comodatario_id,
        'proprietarioId', v_proprietario_id,
        'dataFim', new.data_fim,
        'encerradaEm', now()
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists associacoes_after_update_status on public.associacoes;
create trigger associacoes_after_update_status
  after update of status on public.associacoes
  for each row execute function public.trg_associacoes_after_update_status();
