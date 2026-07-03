-- ============================================================================
-- HABILITAR FUNCIONES DE ENTREGAS Y PAGOS PARA RPC DESDE FLUTTER
-- ============================================================================
-- Este script crea wrappers en el schema public para funciones privadas
-- de entregas parciales y permite registrar pagos.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. mark_items_delivered: marcar ítems entregados y actualizar estado
-- ----------------------------------------------------------------------------
drop function if exists public.mark_items_delivered(uuid, jsonb);

create or replace function public.mark_items_delivered(
  p_order_id uuid,
  p_delivered_items jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.mark_items_delivered(p_order_id, p_delivered_items);
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. record_payment: registrar un pago/abono y actualizar saldo del cliente
-- ----------------------------------------------------------------------------
drop function if exists public.record_payment(uuid, uuid, text, numeric, text, uuid, text);

create or replace function public.record_payment(
  p_order_id uuid default null,
  p_customer_id uuid default null,
  p_payment_method text default 'cash',
  p_amount numeric default 0,
  p_reference text default null,
  p_received_by uuid default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_payment_id uuid;
  v_customer_id uuid;
  v_order_total numeric;
  v_paid_total numeric;
  v_sale_type text;
begin
  -- Validar monto
  if p_amount <= 0 then
    raise exception 'El monto del pago debe ser mayor a cero';
  end if;

  -- Determinar customer_id si viene por order_id
  if p_customer_id is null and p_order_id is not null then
    select customer_id, total, sale_type
    into v_customer_id, v_order_total, v_sale_type
    from public.orders
    where id = p_order_id;
  else
    v_customer_id := p_customer_id;
  end if;

  -- Insertar pago
  insert into public.payments (
    order_id,
    customer_id,
    payment_method,
    amount,
    reference,
    received_by,
    notes
  )
  values (
    p_order_id,
    v_customer_id,
    p_payment_method::public.payment_method,
    p_amount,
    p_reference,
    p_received_by,
    p_notes
  )
  returning id into v_payment_id;

  -- Actualizar saldo del cliente si aplica
  if v_customer_id is not null then
    update public.customers
    set current_balance = current_balance - p_amount
    where id = v_customer_id;
  end if;

  return v_payment_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. VERIFICAR QUE LAS FUNCIONES QUEDARON EXPUESTAS
-- ----------------------------------------------------------------------------
select
  proname as function_name,
  pronamespace::regnamespace as schema
from pg_proc
where proname in ('mark_items_delivered', 'record_payment')
  and pronamespace = 'public'::regnamespace;
