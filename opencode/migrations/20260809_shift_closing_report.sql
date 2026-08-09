-- ============================================================================
-- MIGRACIÓN: Reporte de cierre de caja por turno
-- Fecha: 2026-08-09
-- ============================================================================
--
-- 1. Vincula pedidos y pagos con el turno abierto del usuario (shift_id).
-- 2. Los pagos en efectivo generan automáticamente un ingreso en
--    cash_transactions para cuadrar la caja.
-- 3. Agrega net_total a cash_counts para guardar el conteo ya descontada la
--    base de apertura.
-- 4. Crea RPC get_shift_closing_report(p_date, p_user_id) con ventas por
--    usuario y cuadre de caja.
--
-- Aplicar en Supabase Dashboard → SQL Editor.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. COLUMNAS shift_id EN orders Y payments
-- ----------------------------------------------------------------------------
alter table public.orders
  add column if not exists shift_id uuid references public.shifts(id) on delete set null;

alter table public.payments
  add column if not exists shift_id uuid references public.shifts(id) on delete set null;

create index if not exists idx_orders_shift_id on public.orders(shift_id);
create index if not exists idx_payments_shift_id on public.payments(shift_id);

-- ----------------------------------------------------------------------------
-- 2. COLUMNA net_total EN cash_counts
-- ----------------------------------------------------------------------------
alter table public.cash_counts
  add column if not exists net_total numeric(12,2) not null default 0;

comment on column public.cash_counts.net_total is
  'Efectivo neto: conteo físico total menos la base de apertura del turno';

-- ----------------------------------------------------------------------------
-- 3. TRIGGER: ASIGNAR TURNO A PEDIDOS
-- ----------------------------------------------------------------------------
create or replace function private.assign_shift_to_order()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_shift_id uuid;
begin
  select s.id into v_shift_id
  from public.shifts s
  where s.opened_by = new.seller_id
    and s.status = 'open'
  order by s.opened_at desc
  limit 1;

  if v_shift_id is not null then
    new.shift_id := v_shift_id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_orders_assign_shift on public.orders;
create trigger trg_orders_assign_shift
  before insert on public.orders
  for each row
  execute function private.assign_shift_to_order();

-- ----------------------------------------------------------------------------
-- 4. TRIGGER: ASIGNAR TURNO A PAGOS Y GENERAR CASH_TRANSACTION EN EFECTIVO
-- ----------------------------------------------------------------------------
create or replace function private.assign_shift_and_cash_transaction_to_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_shift_id uuid;
  v_cash_register_id uuid;
begin
  select s.id, s.cash_register_id
  into v_shift_id, v_cash_register_id
  from public.shifts s
  where s.opened_by = new.received_by
    and s.status = 'open'
  order by s.opened_at desc
  limit 1;

  if v_shift_id is not null then
    update public.payments
    set shift_id = v_shift_id
    where id = new.id;

    if new.payment_method = 'cash' then
      insert into public.cash_transactions (
        shift_id,
        cash_register_id,
        transaction_type,
        amount,
        payment_method,
        reference_id,
        reference_type,
        description,
        created_by
      ) values (
        v_shift_id,
        v_cash_register_id,
        'income'::public.cash_transaction_type,
        new.amount,
        new.payment_method,
        new.id,
        'payment',
        'Pago en efectivo',
        new.received_by
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_payments_assign_shift on public.payments;
create trigger trg_payments_assign_shift
  after insert on public.payments
  for each row
  execute function private.assign_shift_and_cash_transaction_to_payment();

-- ----------------------------------------------------------------------------
-- 5. TRIGGER: ELIMINAR CASH_TRANSACTION SI SE BORRA UN PAGO
-- ----------------------------------------------------------------------------
create or replace function private.delete_cash_transaction_on_payment_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.cash_transactions
  where reference_id = old.id
    and reference_type = 'payment';

  return old;
end;
$$;

drop trigger if exists trg_payments_delete_cash_tx on public.payments;
create trigger trg_payments_delete_cash_tx
  after delete on public.payments
  for each row
  execute function private.delete_cash_transaction_on_payment_delete();

-- ----------------------------------------------------------------------------
-- 6. RPC: REPORTE DE CIERRE DE CAJA POR TURNO
-- ----------------------------------------------------------------------------
drop function if exists public.get_shift_closing_report(date, uuid);

create or replace function public.get_shift_closing_report(
  p_date date,
  p_user_id uuid default null
)
returns table(
  shift_id uuid,
  cash_register_name text,
  opened_by_id uuid,
  opened_by_name text,
  opened_at timestamptz,
  closed_at timestamptz,
  opening_amount numeric,
  closing_amount numeric,
  expected_amount numeric,
  difference numeric,
  net_cash_total numeric,
  expected_cash_sales numeric,
  payments_total numeric,
  sales_by_user jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  with shift_data as (
    select
      s.id as sid,
      cr.name as register_name,
      s.opened_by as ob_id,
      p.full_name as ob_name,
      s.opened_at,
      s.closed_at,
      s.opening_amount,
      s.closing_amount,
      s.expected_amount,
      s.difference
    from public.shifts s
    join public.cash_registers cr on cr.id = s.cash_register_id
    join public.profiles p on p.id = s.opened_by
    where s.status = 'closed'
      and s.closed_at is not null
      and (s.closed_at at time zone 'America/Bogota')::date = p_date
  ),
  user_sales as (
    select
      pm.shift_id as sid,
      pm.received_by as uid,
      pr.full_name as uname,
      coalesce(sum(pm.amount), 0) as total
    from public.payments pm
    join public.profiles pr on pr.id = pm.received_by
    where pm.shift_id in (select sid from shift_data)
      and (p_user_id is null or pm.received_by = p_user_id)
    group by pm.shift_id, pm.received_by, pr.full_name
  ),
  shift_user_totals as (
    select
      sid,
      coalesce(sum(total), 0) as payments_total,
      coalesce(
        jsonb_agg(
          jsonb_build_object(
            'user_id', uid,
            'user_name', uname,
            'total_payments', total
          ) order by uname
        ) filter (where uid is not null),
        '[]'::jsonb
      ) as sales_by_user
    from user_sales
    group by sid
  )
  select
    sd.sid,
    sd.register_name,
    sd.ob_id,
    sd.ob_name,
    sd.opened_at,
    sd.closed_at,
    sd.opening_amount,
    sd.closing_amount,
    sd.expected_amount,
    sd.difference,
    coalesce(sd.closing_amount, 0) - coalesce(sd.opening_amount, 0) as net_cash_total,
    coalesce(sd.expected_amount, 0) - coalesce(sd.opening_amount, 0) as expected_cash_sales,
    coalesce(sut.payments_total, 0),
    coalesce(sut.sales_by_user, '[]'::jsonb)
  from shift_data sd
  left join shift_user_totals sut on sut.sid = sd.sid
  where p_user_id is null
     or sd.ob_id = p_user_id
     or exists (select 1 from user_sales us where us.sid = sd.sid)
  order by sd.closed_at desc;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7. VERIFICACIÓN
-- ----------------------------------------------------------------------------
select
  trigger_name,
  event_manipulation,
  event_object_table
from information_schema.triggers
where trigger_name in ('trg_orders_assign_shift', 'trg_payments_assign_shift', 'trg_payments_delete_cash_tx')
order by event_object_table, trigger_name;
