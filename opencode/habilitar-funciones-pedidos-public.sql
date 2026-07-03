-- ============================================================================
-- HABILITAR FUNCIONES PÚBLICAS Y RLS PARA MÓDULO DE PEDIDOS
-- ============================================================================
-- Las funciones de negocio para pedidos están en el schema private por
-- seguridad, pero el cliente Flutter solo puede llamar funciones del schema
-- public vía RPC. Este script crea wrappers públicos y políticas RLS
-- adicionales necesarias para el módulo de pedidos.
-- ============================================================================

-- ============================================================================
-- POLÍTICAS RLS PARA ORDER_ITEMS
-- ============================================================================
-- Eliminar políticas existentes para evitar duplicados
DROP POLICY IF EXISTS "Order items are viewable by authenticated users" ON public.order_items;
DROP POLICY IF EXISTS "Order items can be created by sellers and admins" ON public.order_items;
DROP POLICY IF EXISTS "Order items can be updated by sellers and admins" ON public.order_items;
DROP POLICY IF EXISTS "Order items can be deleted by admins" ON public.order_items;

-- Lectura: todos los usuarios autenticados pueden ver items
CREATE POLICY "Order items are viewable by authenticated users"
  ON public.order_items FOR SELECT
  TO authenticated
  USING (true);

-- Inserción: sellers y admins (la app usa principalmente la función RPC)
CREATE POLICY "Order items can be created by sellers and admins"
  ON public.order_items FOR INSERT
  TO authenticated
  WITH CHECK (private.is_seller_or_admin());

-- Actualización: sellers y admins
CREATE POLICY "Order items can be updated by sellers and admins"
  ON public.order_items FOR UPDATE
  TO authenticated
  USING (private.is_seller_or_admin())
  WITH CHECK (private.is_seller_or_admin());

-- Eliminación: solo admins
CREATE POLICY "Order items can be deleted by admins"
  ON public.order_items FOR DELETE
  TO authenticated
  USING (private.is_admin());

-- ============================================================================
-- WRAPPERS PÚBLICOS PARA FUNCIONES DE PEDIDOS
-- ============================================================================
-- Estas funciones llaman a las funciones privadas que contienen la lógica
-- de negocio. Se ejecutan como security definer para poder invocar funciones
-- del schema private y realizar operaciones atómicas.

-- Wrapper para crear pedido completo con items
DROP FUNCTION IF EXISTS public.create_order_with_items(
  uuid, uuid, sale_type, delivery_type, jsonb, text, text, numeric, numeric, numeric
);

CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_customer_id uuid,
  p_seller_id uuid,
  p_sale_type sale_type,
  p_delivery_type delivery_type,
  p_items jsonb,
  p_notes text DEFAULT NULL,
  p_delivery_address text DEFAULT NULL,
  p_delivery_latitude numeric DEFAULT NULL,
  p_delivery_longitude numeric DEFAULT NULL,
  p_delivery_fee numeric DEFAULT 0
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

-- Wrapper para cancelar pedido completo
DROP FUNCTION IF EXISTS public.cancel_order(uuid, text, uuid);

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

-- Wrapper para editar cantidad de item de pedido
DROP FUNCTION IF EXISTS public.edit_order_item(uuid, uuid, numeric, uuid, text);

CREATE OR REPLACE FUNCTION public.edit_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity numeric,
  p_edited_by uuid,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM private.edit_order_item(
    p_order_id,
    p_order_item_id,
    p_new_quantity,
    p_edited_by,
    p_reason
  );
END;
$$;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================
SELECT 
  'Funciones públicas creadas' as resultado,
  COUNT(*) as cantidad
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('create_order_with_items', 'cancel_order', 'edit_order_item');

SELECT 
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'order_items'
ORDER BY cmd;
