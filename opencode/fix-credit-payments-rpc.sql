-- ============================================================================
-- FIX: Registro de pagos/abonos a crédito y estado completado
-- ============================================================================
-- 1. Permite marcar pedidos como 'completed' cuando se paga el total.
-- 2. Usa el RPC record_payment (security definer) para saltar RLS y que
--    usuarios con rol 'delivery' puedan registrar pagos.
-- 3. Corrige triggers de saldo de cliente para evitar referencias a columnas
--    inexistentes (NEW.order_id en orders, NEW.sale_type en payments).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Agregar estado 'completed' al enum de estados de pedido
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'order_status'
      and e.enumlabel = 'completed'
  ) then
    alter type public.order_status add value 'completed';
  end if;
end
$$;

-- ----------------------------------------------------------------------------
-- 2. Recrear RPC record_payment con lógica de estado completado
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
begin
  -- Validar monto
  if p_amount <= 0 then
    raise exception 'El monto del pago debe ser mayor a cero';
  end if;

  -- Determinar customer_id y total si viene por order_id
  if p_customer_id is null and p_order_id is not null then
    select customer_id, total
    into v_customer_id, v_order_total
    from public.orders
    where id = p_order_id;
  else
    v_customer_id := p_customer_id;
    v_order_total := null;
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

  -- Si el pago cubre el total del pedido, marcar como completado
  if p_order_id is not null and v_order_total is not null then
    select coalesce(sum(amount), 0)
    into v_paid_total
    from public.payments
    where order_id = p_order_id
      and status = 'completed';

    if v_paid_total >= v_order_total then
      update public.orders
      set status = 'completed'::public.order_status
      where id = p_order_id;
    end if;
  end if;

  return v_payment_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Corregir trigger on_order_delivered: función separada para tabla orders
-- ----------------------------------------------------------------------------
create or replace function private.update_customer_balance_on_order()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Cuando un pedido a crédito se entrega, aumentar saldo del cliente
  if tg_op = 'INSERT' and new.sale_type = 'credit' and new.status = 'delivered' then
    update public.customers
    set current_balance = current_balance + new.total
    where id = new.customer_id;
  end if;

  return new;
end;
$$;

drop trigger if exists on_order_delivered on public.orders;

create trigger on_order_delivered
  after update on public.orders
  for each row
  when (old.status != 'delivered' and new.status = 'delivered' and new.sale_type = 'credit')
  execute function private.update_customer_balance_on_order();

-- ----------------------------------------------------------------------------
-- 4. Corregir trigger on_credit_payment: función separada para tabla payments
-- ----------------------------------------------------------------------------
create or replace function private.update_customer_balance_on_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Cuando se registra un pago sin pedido asociado, disminuir saldo del cliente
  if tg_op = 'INSERT' and new.order_id is null and new.customer_id is not null then
    update public.customers
    set current_balance = current_balance - new.amount
    where id = new.customer_id;
  end if;

  return new;
end;
$$;

drop trigger if exists on_credit_payment on public.payments;

create trigger on_credit_payment
  after insert on public.payments
  for each row
  when (new.order_id is null and new.customer_id is not null)
  execute function private.update_customer_balance_on_payment();

-- ----------------------------------------------------------------------------
-- 5. Verificar que todo quedó creado
-- ----------------------------------------------------------------------------
select
  proname as function_name,
  pronamespace::regnamespace as schema
from pg_proc
where proname in ('record_payment', 'update_customer_balance_on_order', 'update_customer_balance_on_payment')
  and pronamespace in ('public'::regnamespace, 'private'::regnamespace);
