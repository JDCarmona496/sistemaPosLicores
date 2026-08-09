-- ============================================================================
-- MIGRACIÓN: Hora del servidor y triggers de auditoría
-- Fecha: 2026-08-08
-- ============================================================================
-- Objetivo: evitar que la hora del dispositivo local genere fechas incorrectas
-- en facturas, entregas y cancelaciones. Supabase (PostgreSQL) es la fuente de
-- verdad de la hora mediante now().
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Función pública para consultar la hora del servidor desde la app
-- ----------------------------------------------------------------------------
create or replace function public.get_server_time()
returns timestamptz
language sql
security definer
as $$
  select now();
$$;

comment on function public.get_server_time() is 'Devuelve la hora actual del servidor de Supabase. Útil para sincronizar la app sin depender del reloj del dispositivo.';

-- ----------------------------------------------------------------------------
-- Trigger: asegurar created_at, updated_at y timestamps de estado en orders
-- ----------------------------------------------------------------------------
create or replace function public.orders_timestamp_trigger()
returns trigger
language plpgsql
as $$
begin
  -- En inserción, usar la hora del servidor si no viene un valor explícito.
  if tg_op = 'INSERT' then
    if new.created_at is null then
      new.created_at := now();
    end if;
    new.updated_at := now();
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();

    -- Marcar entrega con hora del servidor si pasa a entregado.
    if new.status = 'delivered' and old.status is distinct from 'delivered' and new.delivered_at is null then
      new.delivered_at := now();
    end if;

    -- Marcar cancelación con hora del servidor si pasa a cancelado.
    if new.status = 'cancelled' and old.status is distinct from 'cancelled' and new.cancelled_at is null then
      new.cancelled_at := now();
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists orders_timestamp_trigger on public.orders;
create trigger orders_timestamp_trigger
  before insert or update on public.orders
  for each row
  execute function public.orders_timestamp_trigger();

-- ----------------------------------------------------------------------------
-- Trigger: marcar delivered_at en order_items cuando se entrega la cantidad total
-- ----------------------------------------------------------------------------
create or replace function public.order_items_timestamp_trigger()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.created_at is null then
      new.created_at := now();
    end if;
    new.updated_at := now();
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();

    if new.quantity_delivered >= new.quantity and new.delivered_at is null then
      new.delivered_at := now();
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists order_items_timestamp_trigger on public.order_items;
create trigger order_items_timestamp_trigger
  before insert or update on public.order_items
  for each row
  execute function public.order_items_timestamp_trigger();

-- ----------------------------------------------------------------------------
-- Trigger: asegurar created_at/updated_at en payments
-- ----------------------------------------------------------------------------
create or replace function public.payments_timestamp_trigger()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.created_at is null then
      new.created_at := now();
    end if;
    new.updated_at := now();
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists payments_timestamp_trigger on public.payments;
create trigger payments_timestamp_trigger
  before insert or update on public.payments
  for each row
  execute function public.payments_timestamp_trigger();
