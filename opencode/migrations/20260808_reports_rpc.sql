-- ============================================================================
-- MIGRACIÓN: Funciones RPC para el módulo de reportes
-- Fecha: 2026-08-08
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Resumen de ventas por período
-- ----------------------------------------------------------------------------
create or replace function public.get_sales_summary(
  p_date_from date,
  p_date_to date,
  p_seller_id uuid default null
)
returns table (
  total_sales numeric,
  total_orders bigint,
  average_ticket numeric,
  total_discounts numeric,
  total_delivery_fees numeric
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      coalesce(sum(o.total), 0)::numeric as total_sales,
      count(*)::bigint as total_orders,
      coalesce(avg(o.total), 0)::numeric as average_ticket,
      coalesce(sum(o.discount_amount), 0)::numeric as total_discounts,
      coalesce(sum(o.delivery_fee), 0)::numeric as total_delivery_fees
    from public.orders o
    where o.created_at::date between p_date_from and p_date_to
      and o.status not in ('cancelled', 'returned')
      and (v_seller_id is null or o.seller_id = v_seller_id);
end;
$$;

-- ----------------------------------------------------------------------------
-- Ventas por método de pago
-- ----------------------------------------------------------------------------
create or replace function public.get_sales_by_payment_method(
  p_date_from date,
  p_date_to date,
  p_seller_id uuid default null
)
returns table (
  payment_method text,
  amount numeric,
  payment_count bigint
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      p.payment_method::text,
      coalesce(sum(p.amount), 0)::numeric as amount,
      count(*)::bigint as payment_count
    from public.payments p
    where p.created_at::date between p_date_from and p_date_to
      and p.status = 'completed'
      and (v_seller_id is null or p.received_by = v_seller_id)
    group by p.payment_method
    order by amount desc;
end;
$$;

-- ----------------------------------------------------------------------------
-- Productos más vendidos
-- ----------------------------------------------------------------------------
create or replace function public.get_top_products(
  p_date_from date,
  p_date_to date,
  p_limit integer default 10,
  p_seller_id uuid default null
)
returns table (
  product_id uuid,
  product_name text,
  total_quantity bigint,
  total_sales numeric
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      pr.id as product_id,
      pr.name::text as product_name,
      coalesce(sum(oi.quantity), 0)::bigint as total_quantity,
      coalesce(sum(oi.subtotal), 0)::numeric as total_sales
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    join public.products pr on pr.id = oi.product_id
    where o.created_at::date between p_date_from and p_date_to
      and o.status not in ('cancelled', 'returned')
      and (v_seller_id is null or o.seller_id = v_seller_id)
    group by pr.id, pr.name
    order by total_quantity desc
    limit p_limit;
end;
$$;

-- ----------------------------------------------------------------------------
-- Pedidos pendientes (resumen)
-- ----------------------------------------------------------------------------
create or replace function public.get_pending_orders_summary(
  p_seller_id uuid default null
)
returns table (
  pending_count bigint,
  pending_total numeric
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      count(*)::bigint as pending_count,
      coalesce(sum(o.total), 0)::numeric as pending_total
    from public.orders o
    where o.status in ('pending', 'preparing', 'ready', 'in_transit', 'partially_delivered')
      and (v_seller_id is null or o.seller_id = v_seller_id);
end;
$$;

-- ----------------------------------------------------------------------------
-- Ventas por vendedor
-- ----------------------------------------------------------------------------
create or replace function public.get_sales_by_seller(
  p_date_from date,
  p_date_to date,
  p_seller_id uuid default null
)
returns table (
  seller_id uuid,
  seller_name text,
  total_sales numeric,
  order_count bigint
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      p.id as seller_id,
      coalesce(p.full_name, 'Sin nombre')::text as seller_name,
      coalesce(sum(o.total), 0)::numeric as total_sales,
      count(*)::bigint as order_count
    from public.orders o
    join public.profiles p on p.id = o.seller_id
    where o.created_at::date between p_date_from and p_date_to
      and o.status not in ('cancelled', 'returned')
      and (v_seller_id is null or o.seller_id = v_seller_id)
    group by p.id, p.full_name
    order by total_sales desc;
end;
$$;

-- ----------------------------------------------------------------------------
-- Ventas por hora (un día específico)
-- ----------------------------------------------------------------------------
create or replace function public.get_hourly_sales(
  p_date date,
  p_seller_id uuid default null
)
returns table (
  sale_hour integer,
  total_sales numeric,
  order_count bigint
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      extract(hour from o.created_at)::integer as sale_hour,
      coalesce(sum(o.total), 0)::numeric as total_sales,
      count(*)::bigint as order_count
    from public.orders o
    where o.created_at::date = p_date
      and o.status not in ('cancelled', 'returned')
      and (v_seller_id is null or o.seller_id = v_seller_id)
    group by extract(hour from o.created_at)
    order by sale_hour;
end;
$$;

-- ----------------------------------------------------------------------------
-- Tendencia de ventas por día
-- ----------------------------------------------------------------------------
create or replace function public.get_sales_trend(
  p_date_from date,
  p_date_to date,
  p_seller_id uuid default null
)
returns table (
  sale_date date,
  total_sales numeric,
  order_count bigint
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_admin boolean := private.is_admin();
  v_seller_id uuid := p_seller_id;
begin
  if not v_is_admin then
    v_seller_id := v_user_id;
  end if;

  return query
    select
      o.created_at::date as sale_date,
      coalesce(sum(o.total), 0)::numeric as total_sales,
      count(*)::bigint as order_count
    from public.orders o
    where o.created_at::date between p_date_from and p_date_to
      and o.status not in ('cancelled', 'returned')
      and (v_seller_id is null or o.seller_id = v_seller_id)
    group by o.created_at::date
    order by sale_date;
end;
$$;

-- ----------------------------------------------------------------------------
-- Permisos
-- ----------------------------------------------------------------------------
grant execute on function public.get_sales_summary(date, date, uuid) to authenticated;
grant execute on function public.get_sales_by_payment_method(date, date, uuid) to authenticated;
grant execute on function public.get_top_products(date, date, integer, uuid) to authenticated;
grant execute on function public.get_pending_orders_summary(uuid) to authenticated;
grant execute on function public.get_sales_by_seller(date, date, uuid) to authenticated;
grant execute on function public.get_hourly_sales(date, uuid) to authenticated;
grant execute on function public.get_sales_trend(date, date, uuid) to authenticated;
