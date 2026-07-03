-- ============================================================================
-- FIX: Calificar tablas con schema public en create_order_with_items
-- ============================================================================
-- Problema: La función private.create_order_with_items tiene search_path = ''
-- y usa nombres de tabla sin calificar (orders, order_items, inventory_movements),
-- lo que causa el error "relation 'orders' does not exist".
--
-- Solución: Recrear la función calificando todas las tablas con public.
-- ============================================================================

DROP FUNCTION IF EXISTS public.create_order_with_items(
  uuid, uuid, sale_type, delivery_type, jsonb, text, text, numeric, numeric, numeric
);

DROP FUNCTION IF EXISTS private.create_order_with_items(
  uuid, uuid, sale_type, delivery_type, jsonb, text, text, numeric, numeric, numeric
);

CREATE OR REPLACE FUNCTION private.create_order_with_items(
  p_customer_id uuid,
  p_seller_id uuid,
  p_sale_type sale_type,
  p_delivery_type delivery_type,
  p_items jsonb,
  p_notes text default null,
  p_delivery_address text default null,
  p_delivery_latitude numeric default null,
  p_delivery_longitude numeric default null,
  p_delivery_fee numeric default 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
declare
  v_order_id uuid;
  v_order_number integer;
  v_item jsonb;
  v_subtotal numeric := 0;
  v_discount numeric := 0;
  v_total numeric := 0;
  v_product_stock integer;
begin
  -- Obtener siguiente número de pedido
  select coalesce(max(order_number), 0) + 1 into v_order_number from public.orders;

  -- Crear pedido
  insert into public.orders (
    order_number, customer_id, seller_id, sale_type, delivery_type,
    subtotal, discount_amount, delivery_fee, total, notes,
    delivery_address, delivery_latitude, delivery_longitude
  )
  values (
    v_order_number, p_customer_id, p_seller_id, p_sale_type, p_delivery_type,
    0, 0, p_delivery_fee, 0, p_notes,
    p_delivery_address, p_delivery_latitude, p_delivery_longitude
  )
  returning id into v_order_id;

  -- Insertar items y calcular totales
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    -- Validar stock
    select stock_current into v_product_stock
    from public.products
    where id = (v_item->>'product_id')::uuid;

    if v_product_stock < (v_item->>'quantity')::numeric then
      raise exception 'Stock insuficiente para el producto %', (v_item->>'product_id')::uuid;
    end if;

    -- Insertar item
    insert into public.order_items (order_id, product_id, quantity, unit_price, discount_amount, subtotal)
    values (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'quantity')::numeric,
      (v_item->>'unit_price')::numeric,
      coalesce((v_item->>'discount_amount')::numeric, 0),
      ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric) - coalesce((v_item->>'discount_amount')::numeric, 0)
    );

    v_subtotal := v_subtotal + ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric);
    v_discount := v_discount + coalesce((v_item->>'discount_amount')::numeric, 0);

    -- Descontar stock
    update public.products
    set stock_current = stock_current - (v_item->>'quantity')::integer
    where id = (v_item->>'product_id')::uuid;

    -- Registrar movimiento de inventario
    insert into public.inventory_movements (product_id, movement_type, quantity, reference_id, reference_type, created_by)
    values (
      (v_item->>'product_id')::uuid,
      'sale',
      (v_item->>'quantity')::integer,
      v_order_id,
      'order',
      p_seller_id
    );
  end loop;

  v_total := v_subtotal - v_discount + p_delivery_fee;

  -- Actualizar totales del pedido
  update public.orders
  set
    subtotal = v_subtotal,
    discount_amount = v_discount,
    total = v_total
  where id = v_order_id;

  return v_order_id;
end;
$$;

-- Recrear wrapper público
CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_customer_id uuid,
  p_seller_id uuid,
  p_sale_type sale_type,
  p_delivery_type delivery_type,
  p_items jsonb,
  p_notes text default null,
  p_delivery_address text default null,
  p_delivery_latitude numeric default null,
  p_delivery_longitude numeric default null,
  p_delivery_fee numeric default 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN private.create_order_with_items(
    p_customer_id,
    p_seller_id,
    p_sale_type,
    p_delivery_type,
    p_items,
    p_notes,
    p_delivery_address,
    p_delivery_latitude,
    p_delivery_longitude,
    p_delivery_fee
  );
END;
$$;

-- Verificar que la función se recreó correctamente
SELECT 
  'Función create_order_with_items recreada' as mensaje,
  proname,
  pronamespace::regnamespace as schema
FROM pg_proc
WHERE proname = 'create_order_with_items';
