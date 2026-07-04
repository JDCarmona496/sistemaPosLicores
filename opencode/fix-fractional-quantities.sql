-- ============================================================================
-- FIX: Soportar cantidades fraccionadas en pedidos y stock
-- ============================================================================
-- Problema: La BD usaba integer para stock y movimientos, lo que causaba
-- "invalid input syntax for type integer: '6.0'" al enviar cantidades decimales
-- y no permitia vender fracciones (ej: 15 de una canasta de 30).
--
-- Solucion: Cambiar columnas de cantidad a numeric(10,2) y actualizar
-- funciones/triggers que usaban casts a integer.
-- ============================================================================

-- 1. Cambiar columnas de cantidad a numeric(10,2)
ALTER TABLE public.products
  ALTER COLUMN stock_current TYPE numeric(10,2),
  ALTER COLUMN stock_min TYPE numeric(10,2);

ALTER TABLE public.product_lots
  ALTER COLUMN quantity TYPE numeric(10,2),
  ALTER COLUMN quantity_remaining TYPE numeric(10,2);

ALTER TABLE public.inventory_movements
  ALTER COLUMN quantity TYPE numeric(10,2);

ALTER TABLE public.supplier_invoice_items
  ALTER COLUMN quantity TYPE numeric(10,2);

-- customer_baskets se deja en integer porque representa canastas fisicas enteras.

-- 2. Actualizar trigger de stock
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
  v_quantity_change numeric(10,2);
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

-- 3. Actualizar funcion de creacion de pedidos
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
  v_product_stock numeric(10,2);
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

    IF v_product_stock < (v_item->>'quantity')::numeric THEN
      RAISE EXCEPTION 'Stock insuficiente para el producto %', (v_item->>'product_id')::uuid;
    END IF;

    INSERT INTO public.order_items (
      order_id, product_id, quantity, unit_price, discount_amount, subtotal
    )
    VALUES (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'quantity')::numeric,
      (v_item->>'unit_price')::numeric,
      coalesce((v_item->>'discount_amount')::numeric, 0),
      ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric)
        - coalesce((v_item->>'discount_amount')::numeric, 0)
    );

    v_subtotal := v_subtotal + ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric);
    v_discount := v_discount + coalesce((v_item->>'discount_amount')::numeric, 0);

    UPDATE public.products
    SET stock_current = stock_current - (v_item->>'quantity')::numeric
    WHERE id = (v_item->>'product_id')::uuid;

    INSERT INTO public.inventory_movements (
      product_id, movement_type, quantity, reference_id, reference_type, created_by
    )
    VALUES (
      (v_item->>'product_id')::uuid,
      'sale',
      (v_item->>'quantity')::numeric,
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

-- 4. Actualizar funcion de cancelacion (usa oi.quantity en inventory_movements)
-- No requiere cambios de codigo porque inventory_movements.quantity ya es numeric,
-- pero la recreamos para asegurar que no tenga casts integer ocultos.
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

-- 5. Recrear funcion de edicion de item por si acaso
DROP FUNCTION IF EXISTS public.edit_order_item(uuid, uuid, numeric, uuid, text);
DROP FUNCTION IF EXISTS private.edit_order_item(uuid, uuid, numeric, uuid, text);

CREATE OR REPLACE FUNCTION private.edit_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity numeric,
  p_edited_by uuid,
  p_reason text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_quantity numeric;
  v_product_id uuid;
  v_unit_price numeric;
  v_quantity_diff numeric;
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
  p_new_quantity numeric,
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

-- Verificacion
SELECT
  'Columnas y funciones actualizadas para cantidades fraccionadas' as mensaje;
