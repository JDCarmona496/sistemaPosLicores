-- ============================================================================
-- FIX MINIMO: Cambiar columnas de stock de products a numeric
-- ============================================================================
-- Ejecutar esto si al actualizar un producto sale:
-- "invalid input syntax for type integer: 1000.0"
-- ============================================================================

ALTER TABLE public.products
  ALTER COLUMN stock_current TYPE numeric(10,2),
  ALTER COLUMN stock_min TYPE numeric(10,2),
  ALTER COLUMN stock_max TYPE numeric(10,2);

SELECT column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_name = 'products'
  AND column_name IN ('stock_current', 'stock_min', 'stock_max')
ORDER BY column_name;
