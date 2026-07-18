-- ============================================================
-- BUCKET DE SUPABASE STORAGE PARA EVIDENCIAS DE ENTREGA
-- Ejecutar en Supabase SQL Editor antes de usar el módulo.
-- ============================================================

-- 1. Crear bucket para evidencias de entrega
INSERT INTO storage.buckets (id, name, public)
VALUES ('delivery-evidence', 'delivery-evidence', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Políticas RLS para el bucket
-- Los domiciliarios y admins pueden subir evidencias
CREATE POLICY IF NOT EXISTS "delivery_evidence_insert_authenticated"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'delivery-evidence'
  AND (
    -- Solo permitir subir en la estructura orders/{order_id}/...
    storage.foldername(name)[1] = 'orders'
  )
);

-- Todos los usuarios autenticados pueden leer las evidencias
CREATE POLICY IF NOT EXISTS "delivery_evidence_select_authenticated"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'delivery-evidence');

-- Los usuarios pueden eliminar sus propias evidencias
CREATE POLICY IF NOT EXISTS "delivery_evidence_delete_owner"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'delivery-evidence'
  AND owner = auth.uid()
);

-- 3. Verificar que el bucket se creó correctamente
SELECT
  id,
  name,
  public,
  created_at
FROM storage.buckets
WHERE id = 'delivery-evidence';
