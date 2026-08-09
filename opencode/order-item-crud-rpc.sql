-- ============================================================================
-- FIX: CRUD completo de ítems de pedido (agregar, editar cantidad, eliminar)
-- ============================================================================
-- Permite modificar los ítems de un pedido sin importar su estado, con las
-- siguientes protecciones:
--   - No se puede eliminar un ítem que ya tenga cantidad entregada.
--   - No se puede dejar la cantidad por debajo de la cantidad entregada.
--   - Se ajusta stock, totales y saldo del cliente automáticamente.
--   - Se registra auditoría en order_edits.
--
-- El archivo debe ejecutarse en Supabase SQL Editor.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Helper: recalcular totales del pedido
-- ----------------------------------------------------------------------------
create or replace function private.recalc_order_totals(p_order_id uuid)
returns numeric
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_subtotal numeric;
  v_total numeric;
  v_tax numeric;
  v_delivery_fee numeric;
  v_discount numeric;
begin
  select
    coalesce(sum(subtotal), 0),
    tax_amount,
    delivery_fee,
    discount_amount
  into v_subtotal, v_tax, v_delivery_fee, v_discount
  from public.orders
  where id = p_order_id;

  v_total := v_subtotal + v_tax + v_delivery_fee - v_discount;

  update public.orders
  set
    subtotal = v_subtotal,
    total = v_total,
    edit_count = edit_count + 1
  where id = p_order_id;

  return v_total;
end;
$$;

-- ----------------------------------------------------------------------------
-- Helper: ajustar saldo del cliente para pedidos a crédito ya entregados/pagados
-- ----------------------------------------------------------------------------
create or replace function private.adjust_credit_balance_after_edit(
  p_order_id uuid,
  p_old_total numeric,
  p_new_total numeric
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_customer_id uuid;
  v_sale_type text;
  v_status text;
  v_delta numeric;
begin
  select customer_id, sale_type, status
  into v_customer_id, v_sale_type, v_status
  from public.orders
  where id = p_order_id;

  if v_customer_id is null or v_sale_type != 'credit' then
    return;
  end if;

  -- Solo ajustar saldo si el pedido ya impactó el saldo (entregado o completado).
  if v_status not in ('delivered', 'completed') then
    return;
  end if;

  v_delta := p_new_total - p_old_total;

  if v_delta <> 0 then
    update public.customers
    set current_balance = current_balance + v_delta
    where id = v_customer_id;
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- Helper: recomputar estado de entrega después de editar ítems
-- ----------------------------------------------------------------------------
create or replace function private.recompute_delivery_status(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_total_items integer;
  v_delivered_items integer;
  v_delivery_type text;
  v_current_status text;
begin
  select delivery_type, status
  into v_delivery_type, v_current_status
  from public.orders
  where id = p_order_id;

  -- Para pedidos en tienda siempre quedan entregados.
  if v_delivery_type = 'in_store' then
    update public.order_items
    set quantity_delivered = quantity, delivered_at = coalesce(delivered_at, now())
    where order_id = p_order_id and quantity_delivered < quantity;

    update public.orders
    set status = 'delivered'
    where id = p_order_id;
    return;
  end if;

  -- Solo recomputar si el pedido ya había sido entregado/completado.
  if v_current_status not in ('delivered', 'completed') then
    return;
  end if;

  select count(*) into v_total_items from public.order_items where order_id = p_order_id;
  select count(*)
  into v_delivered_items
  from public.order_items
  where order_id = p_order_id and quantity_delivered >= quantity;

  update public.orders
  set
    status = case
      when v_delivered_items = 0 then 'in_transit'::public.order_status
      when v_delivered_items < v_total_items then 'partially_delivered'::public.order_status
      else 'delivered'::public.order_status
    end,
    delivered_at = case
      when v_delivered_items = v_total_items then now()
      else delivered_at
    end
  where id = p_order_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 1. Agregar ítem a pedido existente
-- ----------------------------------------------------------------------------
create or replace function private.add_order_item(
  p_order_id uuid,
  p_product_id uuid,
  p_quantity numeric,
  p_unit_price numeric,
  p_discount_amount numeric default 0,
  p_price_type text default 'retail',
  p_notes text default null,
  p_edited_by uuid default null,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order record;
  v_stock numeric;
  v_subtotal numeric;
  v_new_total numeric;
  v_old_total numeric;
  v_quantity_delivered numeric;
  v_delivered_at timestamptz;
  v_order_item_id uuid;
begin
  -- Datos del pedido
  select
    id,
    customer_id,
    sale_type,
    delivery_type,
    status,
    total,
    tax_amount,
    delivery_fee,
    discount_amount
  into v_order
  from public.orders
  where id = p_order_id;

  if v_order is null then
    raise exception 'Pedido no encontrado';
  end if;

  if p_quantity <= 0 then
    raise exception 'La cantidad debe ser mayor a cero';
  end if;

  -- Validar stock
  select stock_current into v_stock
  from public.products
  where id = p_product_id;

  if v_stock is null then
    raise exception 'Producto no encontrado';
  end if;

  if v_stock < p_quantity then
    raise exception 'Stock insuficiente para el producto %', p_product_id;
  end if;

  v_subtotal := (p_quantity * p_unit_price) - p_discount_amount;
  v_old_total := v_order.total;

  -- Para pedidos en tienda los nuevos ítems quedan entregados de inmediato.
  if v_order.delivery_type = 'in_store' then
    v_quantity_delivered := p_quantity;
    v_delivered_at := now();
  else
    v_quantity_delivered := 0;
    v_delivered_at := null;
  end if;

  -- Insertar ítem
  insert into public.order_items (
    order_id,
    product_id,
    quantity,
    quantity_delivered,
    unit_price,
    discount_amount,
    subtotal,
    price_type,
    notes,
    delivered_at
  )
  values (
    p_order_id,
    p_product_id,
    p_quantity,
    v_quantity_delivered,
    p_unit_price,
    p_discount_amount,
    v_subtotal,
    p_price_type,
    p_notes,
    v_delivered_at
  )
  returning id into v_order_item_id;

  -- Descontar stock
  update public.products
  set stock_current = stock_current - p_quantity
  where id = p_product_id;

  -- Movimiento de inventario
  insert into public.inventory_movements (
    product_id,
    movement_type,
    quantity,
    reference_id,
    reference_type,
    notes,
    created_by
  )
  values (
    p_product_id,
    'sale',
    p_quantity,
    p_order_id,
    'order',
    'Edición de pedido: agregar producto',
    p_edited_by
  );

  -- Recalcular totales
  v_new_total := private.recalc_order_totals(p_order_id);

  -- Ajustar saldo del cliente si aplica
  perform private.adjust_credit_balance_after_edit(p_order_id, v_old_total, v_new_total);

  -- Recomputar estado de entrega si aplica
  perform private.recompute_delivery_status(p_order_id);

  -- Auditoría
  insert into public.order_edits (
    order_id,
    edited_by,
    edit_type,
    field_changed,
    old_value,
    new_value,
    reason
  )
  values (
    p_order_id,
    p_edited_by,
    'add_item',
    'items',
    null,
    jsonb_build_object(
      'product_id', p_product_id,
      'quantity', p_quantity,
      'unit_price', p_unit_price,
      'subtotal', v_subtotal
    ),
    p_reason
  );

  return v_order_item_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. Editar cantidad de ítem de pedido (sin restricción de estado)
-- ----------------------------------------------------------------------------
create or replace function private.edit_order_item_v2(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity numeric,
  p_edited_by uuid default null,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order record;
  v_item record;
  v_quantity_diff numeric;
  v_new_subtotal numeric;
  v_old_total numeric;
  v_new_total numeric;
  v_stock numeric;
begin
  -- Datos del pedido
  select
    id,
    customer_id,
    sale_type,
    delivery_type,
    status,
    total,
    tax_amount,
    delivery_fee,
    discount_amount
  into v_order
  from public.orders
  where id = p_order_id;

  if v_order is null then
    raise exception 'Pedido no encontrado';
  end if;

  if p_new_quantity <= 0 then
    raise exception 'La cantidad debe ser mayor a cero. Para eliminar el ítem usa remove_order_item.';
  end if;

  -- Datos del ítem
  select
    quantity,
    quantity_delivered,
    product_id,
    unit_price,
    discount_amount,
    subtotal
  into v_item
  from public.order_items
  where id = p_order_item_id and order_id = p_order_id;

  if v_item is null then
    raise exception 'Ítem no encontrado en el pedido';
  end if;

  -- No permitir cantidad menor a la entregada
  if p_new_quantity < v_item.quantity_delivered then
    raise exception 'La nueva cantidad no puede ser menor a la cantidad ya entregada (%)', v_item.quantity_delivered;
  end if;

  v_quantity_diff := p_new_quantity - v_item.quantity;
  v_old_total := v_order.total;

  -- Validar stock si aumenta la cantidad
  if v_quantity_diff > 0 then
    select stock_current into v_stock
    from public.products
    where id = v_item.product_id;

    if v_stock < v_quantity_diff then
      raise exception 'Stock insuficiente para aumentar la cantidad';
    end if;
  end if;

  v_new_subtotal := (p_new_quantity * v_item.unit_price) - v_item.discount_amount;

  -- Actualizar ítem
  update public.order_items
  set
    quantity = p_new_quantity,
    subtotal = v_new_subtotal
  where id = p_order_item_id;

  -- Ajustar stock
  if v_quantity_diff > 0 then
    update public.products
    set stock_current = stock_current - v_quantity_diff
    where id = v_item.product_id;

    insert into public.inventory_movements (
      product_id,
      movement_type,
      quantity,
      reference_id,
      reference_type,
      notes,
      created_by
    )
    values (
      v_item.product_id,
      'sale',
      v_quantity_diff,
      p_order_id,
      'order',
      'Edición de pedido: aumento de cantidad',
      p_edited_by
    );
  elsif v_quantity_diff < 0 then
    update public.products
    set stock_current = stock_current + abs(v_quantity_diff)
    where id = v_item.product_id;

    insert into public.inventory_movements (
      product_id,
      movement_type,
      quantity,
      reference_id,
      reference_type,
      notes,
      created_by
    )
    values (
      v_item.product_id,
      'return_in',
      abs(v_quantity_diff),
      p_order_id,
      'order',
      'Edición de pedido: disminución de cantidad',
      p_edited_by
    );
  end if;

  -- Recalcular totales
  v_new_total := private.recalc_order_totals(p_order_id);

  -- Ajustar saldo del cliente si aplica
  perform private.adjust_credit_balance_after_edit(p_order_id, v_old_total, v_new_total);

  -- Recomputar estado de entrega si aplica
  perform private.recompute_delivery_status(p_order_id);

  -- Auditoría
  insert into public.order_edits (
    order_id,
    edited_by,
    edit_type,
    field_changed,
    old_value,
    new_value,
    reason
  )
  values (
    p_order_id,
    p_edited_by,
    'change_quantity',
    'quantity',
    jsonb_build_object('quantity', v_item.quantity, 'subtotal', v_item.subtotal),
    jsonb_build_object('quantity', p_new_quantity, 'subtotal', v_new_subtotal),
    p_reason
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Eliminar ítem de pedido
-- ----------------------------------------------------------------------------
create or replace function private.remove_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_edited_by uuid default null,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order record;
  v_item record;
  v_old_total numeric;
  v_new_total numeric;
begin
  -- Datos del pedido
  select
    id,
    customer_id,
    sale_type,
    delivery_type,
    status,
    total,
    tax_amount,
    delivery_fee,
    discount_amount
  into v_order
  from public.orders
  where id = p_order_id;

  if v_order is null then
    raise exception 'Pedido no encontrado';
  end if;

  -- Datos del ítem
  select
    quantity,
    quantity_delivered,
    product_id,
    unit_price,
    discount_amount,
    subtotal
  into v_item
  from public.order_items
  where id = p_order_item_id and order_id = p_order_id;

  if v_item is null then
    raise exception 'Ítem no encontrado en el pedido';
  end if;

  -- No permitir eliminar ítems ya entregados
  if v_item.quantity_delivered > 0 then
    raise exception 'No se puede eliminar un ítem que ya tiene cantidad entregada';
  end if;

  v_old_total := v_order.total;

  -- Devolver stock
  update public.products
  set stock_current = stock_current + v_item.quantity
  where id = v_item.product_id;

  -- Movimiento de inventario
  insert into public.inventory_movements (
    product_id,
    movement_type,
    quantity,
    reference_id,
    reference_type,
    notes,
    created_by
  )
  values (
    v_item.product_id,
    'return_in',
    v_item.quantity,
    p_order_id,
    'order',
    'Edición de pedido: eliminación de producto',
    p_edited_by
  );

  -- Eliminar ítem
  delete from public.order_items
  where id = p_order_item_id;

  -- Recalcular totales
  v_new_total := private.recalc_order_totals(p_order_id);

  -- Ajustar saldo del cliente si aplica
  perform private.adjust_credit_balance_after_edit(p_order_id, v_old_total, v_new_total);

  -- Recomputar estado de entrega si aplica
  perform private.recompute_delivery_status(p_order_id);

  -- Auditoría
  insert into public.order_edits (
    order_id,
    edited_by,
    edit_type,
    field_changed,
    old_value,
    new_value,
    reason
  )
  values (
    p_order_id,
    p_edited_by,
    'remove_item',
    'items',
    jsonb_build_object(
      'product_id', v_item.product_id,
      'quantity', v_item.quantity,
      'unit_price', v_item.unit_price,
      'subtotal', v_item.subtotal
    ),
    null,
    p_reason
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Wrappers públicos para RPC desde Flutter
-- ----------------------------------------------------------------------------
drop function if exists public.add_order_item(
  uuid, uuid, numeric, numeric, numeric, text, text, uuid, text
);

create or replace function public.add_order_item(
  p_order_id uuid,
  p_product_id uuid,
  p_quantity numeric,
  p_unit_price numeric,
  p_discount_amount numeric default 0,
  p_price_type text default 'retail',
  p_notes text default null,
  p_edited_by uuid default null,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  return private.add_order_item(
    p_order_id,
    p_product_id,
    p_quantity,
    p_unit_price,
    p_discount_amount,
    p_price_type,
    p_notes,
    p_edited_by,
    p_reason
  );
end;
$$;

drop function if exists public.edit_order_item_v2(
  uuid, uuid, numeric, uuid, text
);

create or replace function public.edit_order_item_v2(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity numeric,
  p_edited_by uuid default null,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.edit_order_item_v2(
    p_order_id,
    p_order_item_id,
    p_new_quantity,
    p_edited_by,
    p_reason
  );
end;
$$;

drop function if exists public.remove_order_item(
  uuid, uuid, uuid, text
);

create or replace function public.remove_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_edited_by uuid default null,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.remove_order_item(
    p_order_id,
    p_order_item_id,
    p_edited_by,
    p_reason
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 5. Permisos
-- ----------------------------------------------------------------------------
grant execute on function public.add_order_item(
  uuid, uuid, numeric, numeric, numeric, text, text, uuid, text
) to authenticated;

grant execute on function public.edit_order_item_v2(
  uuid, uuid, numeric, uuid, text
) to authenticated;

grant execute on function public.remove_order_item(
  uuid, uuid, uuid, text
) to authenticated;

-- ----------------------------------------------------------------------------
-- 6. Verificación
-- ----------------------------------------------------------------------------
select
  proname as function_name,
  pronamespace::regnamespace as schema
from pg_proc
where proname in ('add_order_item', 'edit_order_item_v2', 'remove_order_item')
  and pronamespace in ('public'::regnamespace, 'private'::regnamespace)
order by pronamespace, proname;
