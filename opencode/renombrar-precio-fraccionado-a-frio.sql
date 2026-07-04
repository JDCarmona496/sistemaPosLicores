-- ============================================================================
-- RENOMBRAR: price_wholesale_fractional -> price_cold
-- ============================================================================
-- Actualiza el nombre de la columna en products para reflejar el concepto
-- de negocio "Precio Frio" (venta suelta de un paquete).
-- ============================================================================

ALTER TABLE public.products
  RENAME COLUMN price_wholesale_fractional TO price_cold;

COMMENT ON COLUMN public.products.price_cold IS
  'Precio frio por unidad, usado para venta suelta de un paquete (ej: 15 unidades de una canasta de 30)';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products' AND column_name = 'price_cold';
