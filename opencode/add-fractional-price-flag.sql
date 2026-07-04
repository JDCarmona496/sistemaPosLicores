-- ============================================================================
-- ADD: Bandera is_fractional_price en order_items
-- ============================================================================
-- Permite distinguir entre precio detal, mayorista y fraccionado en cada item.
-- ============================================================================

-- 1. Agregar columna
ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS is_fractional_price boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.order_items.is_fractional_price IS 'Indica si se aplico precio fraccionado (unidades sueltas de un paquete)';

-- 2. Actualizar funcion de creacion de pedidos
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
      order_id, product_id, quantity, unit_price, discount_amount, subtotal,
      is_wholesale_price, is_fractional_price
    )
    VALUES (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'quantity')::numeric,
      (v_item->>'unit_price')::numeric,
      coalesce((v_item->>'discount_amount')::numeric, 0),
      ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric)
        - coalesce((v_item->>'discount_amount')::numeric, 0),
      coalesce((v_item->>'is_wholesale_price')::boolean, false),
      coalesce((v_item->>'is_fractional_price')::boolean, false)
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

-- Verificacion
SELECT
  'Columna is_fractional_price agregada y funcion actualizada' as mensaje;
