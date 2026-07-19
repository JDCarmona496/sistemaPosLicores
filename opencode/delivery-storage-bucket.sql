-- ============================================================
-- BUCKET DE SUPABASE STORAGE PARA EVIDENCIAS DE ENTREGA
-- ============================================================
--
-- PASO 1: Ejecutar esto en Supabase SQL Editor (crea el bucket).
-- PASO 2: Crear las políticas manualmente en Supabase Dashboard:
--         Storage > Policies > delivery-evidence > New policy
--         (el SQL Editor normalmente no tiene permisos de owner
--          sobre storage.objects para CREATE/DROP POLICY).
-- ============================================================

-- 1. Crear bucket público para evidencias de entrega
INSERT INTO storage.buckets (id, name, public)
VALUES ('delivery-evidence', 'delivery-evidence', true)
ON CONFLICT (id) DO NOTHING;

-- Verificar que el bucket se creó correctamente
SELECT
  id,
  name,
  public,
  created_at
FROM storage.buckets
WHERE id = 'delivery-evidence';

-- ============================================================
-- POLÍTICAS A CREAR MANUALMENTE EN SUPABASE DASHBOARD
-- Storage → Policies → delivery-evidence → New policy
-- ============================================================
--
-- POLÍTICA 1: delivery_evidence_insert_authenticated
-- Allowed operation: INSERT
-- Target roles: authenticated
-- WITH CHECK expression:
--   (bucket_id = 'delivery-evidence')
--   AND ((storage.foldername(name))[1] = 'orders')
--
-- POLÍTICA 2: delivery_evidence_select_authenticated
-- Allowed operation: SELECT
-- Target roles: authenticated
-- USING expression:
--   (bucket_id = 'delivery-evidence')
--
-- POLÍTICA 3: delivery_evidence_delete_owner
-- Allowed operation: DELETE
-- Target roles: authenticated
-- USING expression:
--   (bucket_id = 'delivery-evidence')
--   AND (owner = auth.uid())
--
-- NOTA: Asegúrate de que Row Level Security esté habilitado
-- para storage.objects (viene habilitado por defecto en Supabase).
