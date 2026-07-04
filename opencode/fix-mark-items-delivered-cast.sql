-- ============================================================================
-- FIX: Casteo de status en mark_items_delivered
-- ============================================================================
-- Error: column "status" is of type public.order_status but expression is of type text
-- Solucion: castear los valores de texto al enum public.order_status.
-- ============================================================================

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

SELECT 'Funcion mark_items_delivered corregida con casteo de status' as mensaje;
