-- ============================================================================
-- NORMALIZACION: Stock y cantidades como integer; tipo de precio unificado
-- ============================================================================
-- Reglas de negocio:
--   - No se parten botellas/cervezas; todo es entero.
--   - Los pedidos pueden vender unidades sueltas de un paquete (ej: 15 de 30),
--     pero la cantidad siempre es un numero entero.
--   - El tipo de precio se guarda en un solo campo: price_type.
-- ============================================================================

-- 1. Stock de productos a integer
ALTER TABLE public.products
  ALTER COLUMN stock_current TYPE integer,
  ALTER COLUMN stock_min TYPE integer,
  ALTER COLUMN stock_max TYPE integer;

-- 2. Cantidades de items de pedido a integer y tipo de precio unificado
ALTER TABLE public.order_items
  ALTER COLUMN quantity TYPE integer,
  ALTER COLUMN quantity_delivered TYPE integer;

ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS price_type text NOT NULL DEFAULT 'retail';

-- Migrar tipos de precio desde las banderas anteriores (solo si aun existen)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'order_items' AND column_name = 'is_wholesale_price'
  ) THEN
    UPDATE public.order_items
    SET price_type = CASE
      WHEN is_fractional_price THEN 'cold'
      WHEN is_wholesale_price THEN 'wholesale'
      ELSE 'retail'
    END
    WHERE price_type = 'retail'
      AND (is_wholesale_price IS TRUE OR is_fractional_price IS TRUE);

    ALTER TABLE public.order_items
      DROP COLUMN IF EXISTS is_wholesale_price,
      DROP COLUMN IF EXISTS is_fractional_price;
  END IF;
END
$$;

-- 3. Movimientos de inventario a integer
ALTER TABLE public.inventory_movements
  ALTER COLUMN quantity TYPE integer;

-- 4. Lotes a integer
ALTER TABLE public.product_lots
  ALTER COLUMN quantity TYPE integer,
  ALTER COLUMN quantity_remaining TYPE integer;

-- 5. Facturas de proveedor a integer
ALTER TABLE public.supplier_invoice_items
  ALTER COLUMN quantity TYPE integer;

-- 6. Recrear funcion de actualizacion de stock
DROP TRIGGER IF EXISTS on_inventory_movement ON public.inventory_movements;
DROP FUNCTION IF EXISTS private.update_product_stock();

CREATE OR REPLACE FUNCTION private.update_product_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_product_id uuid;
  v_quantity_change integer;
BEGIN
  v_product_id := new.product_id;

  CASE new.movement_type
    WHEN 'purchase', 'return_in', 'adjustment_plus' THEN
      v_quantity_change := new.quantity;
    WHEN 'sale', 'return_out', 'adjustment_minus', 'damage', 'expired', 'internal_use' THEN
      v_quantity_change := -new.quantity;
  END CASE;

  UPDATE public.products
  SET stock_current = stock_current + v_quantity_change
  WHERE id = v_product_id;

  RETURN new;
END;
$$;

CREATE TRIGGER on_inventory_movement
  AFTER INSERT ON public.inventory_movements
  FOR EACH ROW EXECUTE FUNCTION private.update_product_stock();

-- 7. Recrear funcion de creacion de pedidos
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
  p_notes text DEFAULT null,
  p_delivery_address text DEFAULT null,
  p_delivery_latitude numeric DEFAULT null,
  p_delivery_longitude numeric DEFAULT null,
  p_delivery_fee numeric DEFAULT 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_id uuid;
  v_order_number integer;
  v_item jsonb;
  v_subtotal numeric := 0;
  v_discount numeric := 0;
  v_total numeric := 0;
  v_product_stock integer;
BEGIN
  SELECT coalesce(max(order_number), 0) + 1 INTO v_order_number FROM public.orders;

  INSERT INTO public.orders (
    order_number, customer_id, seller_id, sale_type, delivery_type,
    subtotal, discount_amount, delivery_fee, total, notes,
    delivery_address, delivery_latitude, delivery_longitude
  )
  VALUES (
    v_order_number, p_customer_id, p_seller_id, p_sale_type, p_delivery_type,
    0, 0, p_delivery_fee, 0, p_notes,
    p_delivery_address, p_delivery_latitude, p_delivery_longitude
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    SELECT stock_current INTO v_product_stock
    FROM public.products
    WHERE id = (v_item->>'product_id')::uuid;

    IF v_product_stock < (v_item->>'quantity')::integer THEN
      RAISE EXCEPTION 'Stock insuficiente para el producto %', (v_item->>'product_id')::uuid;
    END IF;

    INSERT INTO public.order_items (
      order_id, product_id, quantity, unit_price, discount_amount, subtotal, price_type
    )
    VALUES (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'quantity')::integer,
      (v_item->>'unit_price')::numeric,
      coalesce((v_item->>'discount_amount')::numeric, 0),
      ((v_item->>'quantity')::integer * (v_item->>'unit_price')::numeric)
        - coalesce((v_item->>'discount_amount')::numeric, 0),
      coalesce((v_item->>'price_type')::text, 'retail')
    );

    v_subtotal := v_subtotal + ((v_item->>'quantity')::integer * (v_item->>'unit_price')::numeric);
    v_discount := v_discount + coalesce((v_item->>'discount_amount')::numeric, 0);

    UPDATE public.products
    SET stock_current = stock_current - (v_item->>'quantity')::integer
    WHERE id = (v_item->>'product_id')::uuid;

    INSERT INTO public.inventory_movements (
      product_id, movement_type, quantity, reference_id, reference_type, created_by
    )
    VALUES (
      (v_item->>'product_id')::uuid,
      'sale',
      (v_item->>'quantity')::integer,
      v_order_id,
      'order',
      p_seller_id
    );
  END LOOP;

  v_total := v_subtotal - v_discount + p_delivery_fee;

  UPDATE public.orders
  SET
    subtotal = v_subtotal,
    discount_amount = v_discount,
    total = v_total
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_customer_id uuid,
  p_seller_id uuid,
  p_sale_type sale_type,
  p_delivery_type delivery_type,
  p_items jsonb,
  p_notes text DEFAULT null,
  p_delivery_address text DEFAULT null,
  p_delivery_latitude numeric DEFAULT null,
  p_delivery_longitude numeric DEFAULT null,
  p_delivery_fee numeric DEFAULT 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN private.create_order_with_items(
    p_customer_id, p_seller_id, p_sale_type, p_delivery_type,
    p_items, p_notes, p_delivery_address, p_delivery_latitude,
    p_delivery_longitude, p_delivery_fee
  );
END;
$$;

-- 8. Recrear funcion de cancelacion
DROP FUNCTION IF EXISTS public.cancel_order(uuid, text, uuid);
DROP FUNCTION IF EXISTS private.cancel_order(uuid, text, uuid);

CREATE OR REPLACE FUNCTION private.cancel_order(
  p_order_id uuid,
  p_reason text,
  p_cancelled_by uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_status text;
  v_sale_type text;
  v_customer_id uuid;
  v_order_total numeric;
BEGIN
  SELECT status, sale_type, customer_id, total
  INTO v_order_status, v_sale_type, v_customer_id, v_order_total
  FROM public.orders
  WHERE id = p_order_id;

  IF v_order_status = 'delivered' THEN
    RAISE EXCEPTION 'No se puede cancelar un pedido entregado';
  END IF;

  UPDATE public.products p
  SET stock_current = stock_current + oi.quantity
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id
    AND oi.product_id = p.id;

  INSERT INTO public.inventory_movements (
    product_id, movement_type, quantity, reference_id, reference_type, notes, created_by
  )
  SELECT
    oi.product_id,
    'return_in',
    oi.quantity,
    p_order_id,
    'order',
    'Cancelacion de pedido: ' || p_reason,
    p_cancelled_by
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id;

  IF v_sale_type = 'credit' AND v_customer_id IS NOT NULL THEN
    UPDATE public.customers
    SET current_balance = current_balance - v_order_total
    WHERE id = v_customer_id;
  END IF;

  UPDATE public.orders
  SET
    status = 'cancelled',
    cancelled_reason = p_reason,
    cancelled_by = p_cancelled_by,
    cancelled_at = now()
  WHERE id = p_order_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_order(
  p_order_id uuid,
  p_reason text,
  p_cancelled_by uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM private.cancel_order(p_order_id, p_reason, p_cancelled_by);
END;
$$;

-- 9. Recrear funcion de edicion de item
DROP FUNCTION IF EXISTS public.edit_order_item(uuid, uuid, integer, uuid, text);
DROP FUNCTION IF EXISTS private.edit_order_item(uuid, uuid, integer, uuid, text);

CREATE OR REPLACE FUNCTION private.edit_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity integer,
  p_edited_by uuid,
  p_reason text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_quantity integer;
  v_product_id uuid;
  v_unit_price numeric;
  v_quantity_diff integer;
  v_new_subtotal numeric;
BEGIN
  IF p_new_quantity <= 0 THEN
    RAISE EXCEPTION 'La nueva cantidad debe ser mayor a cero';
  END IF;

  SELECT quantity, product_id, unit_price
  INTO v_old_quantity, v_product_id, v_unit_price
  FROM public.order_items
  WHERE id = p_order_item_id AND order_id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Item no encontrado';
  END IF;

  v_quantity_diff := p_new_quantity - v_old_quantity;
  v_new_subtotal := p_new_quantity * v_unit_price;

  UPDATE public.order_items
  SET
    quantity = p_new_quantity,
    subtotal = v_new_subtotal
  WHERE id = p_order_item_id;

  IF v_quantity_diff > 0 THEN
    UPDATE public.products
    SET stock_current = stock_current - v_quantity_diff
    WHERE id = v_product_id;

    INSERT INTO public.inventory_movements (
      product_id, movement_type, quantity, reference_id, reference_type, notes, created_by
    )
    VALUES (
      v_product_id, 'sale', v_quantity_diff, p_order_id, 'order',
      'Edicion de pedido: aumento de cantidad', p_edited_by
    );
  ELSIF v_quantity_diff < 0 THEN
    UPDATE public.products
    SET stock_current = stock_current + abs(v_quantity_diff)
    WHERE id = v_product_id;

    INSERT INTO public.inventory_movements (
      product_id, movement_type, quantity, reference_id, reference_type, notes, created_by
    )
    VALUES (
      v_product_id, 'return_in', abs(v_quantity_diff), p_order_id, 'order',
      'Edicion de pedido: disminucion de cantidad', p_edited_by
    );
  END IF;

  INSERT INTO public.order_edits (
    order_id, edited_by, edit_type, field_name, old_value, new_value, reason
  )
  VALUES (
    p_order_id, p_edited_by, 'change_quantity', 'quantity',
    jsonb_build_object('quantity', v_old_quantity, 'subtotal', v_old_quantity * v_unit_price),
    jsonb_build_object('quantity', p_new_quantity, 'subtotal', v_new_subtotal),
    p_reason
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.edit_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity integer,
  p_edited_by uuid,
  p_reason text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM private.edit_order_item(p_order_id, p_order_item_id, p_new_quantity, p_edited_by, p_reason);
END;
$$;

-- 10. Recrear funcion de entrega parcial
DROP FUNCTION IF EXISTS public.mark_items_delivered(uuid, jsonb);
DROP FUNCTION IF EXISTS private.mark_items_delivered(uuid, jsonb);

CREATE OR REPLACE FUNCTION private.mark_items_delivered(
  p_order_id uuid,
  p_delivered_items jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_item jsonb;
  v_total_items integer;
  v_delivered_items integer;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_delivered_items)
  LOOP
    UPDATE public.order_items
    SET
      quantity_delivered = quantity_delivered + (v_item->>'quantity_delivered')::integer,
      delivered_at = CASE
        WHEN (quantity_delivered + (v_item->>'quantity_delivered')::integer) >= quantity THEN now()
        ELSE delivered_at
      END
    WHERE id = (v_item->>'order_item_id')::uuid
      AND order_id = p_order_id;
  END LOOP;

  SELECT count(*) INTO v_total_items FROM public.order_items WHERE order_id = p_order_id;
  SELECT count(*) INTO v_delivered_items
  FROM public.order_items
  WHERE order_id = p_order_id AND quantity_delivered >= quantity;

  UPDATE public.orders
  SET
    status = CASE
      WHEN v_delivered_items = 0 THEN 'in_transit'::public.order_status
      WHEN v_delivered_items < v_total_items THEN 'partially_delivered'::public.order_status
      ELSE 'delivered'::public.order_status
    END,
    delivered_at = CASE
      WHEN v_delivered_items = v_total_items THEN now()
      ELSE delivered_at
    END
  WHERE id = p_order_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_items_delivered(
  p_order_id uuid,
  p_delivered_items jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM private.mark_items_delivered(p_order_id, p_delivered_items);
END;
$$;

-- Verificacion
SELECT
  'Stock y cantidades normalizadas a integer; price_type unificado' as mensaje;
