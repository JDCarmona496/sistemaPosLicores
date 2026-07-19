-- ============================================================
-- BUCKET DE SUPABASE STORAGE PARA EVIDENCIAS DE ENTREGA
-- Ejecutar en Supabase SQL Editor antes de usar el módulo.
-- ============================================================

-- 1. Asegurar que RLS esté activo en storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Crear bucket para evidencias de entrega
INSERT INTO storage.buckets (id, name, public)
VALUES ('delivery-evidence', 'delivery-evidence', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Eliminar políticas viejas si existen
DROP POLICY IF EXISTS "delivery_evidence_insert_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "delivery_evidence_select_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "delivery_evidence_delete_owner" ON storage.objects;

-- 4. Políticas RLS para el bucket
-- Los domiciliarios pueden subir evidencias de sus pedidos
CREATE POLICY "delivery_evidence_insert_authenticated"
ON storage.objects
FOR INSERT
TO authenticated
  WITH CHECK (
  bucket_id = 'delivery-evidence'
  AND (storage.foldername(name))[1] = 'orders'
);

-- Todos los usuarios autenticados pueden leer las evidencias
CREATE POLICY "delivery_evidence_select_authenticated"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'delivery-evidence');

-- Cada usuario puede eliminar sus propias evidencias
CREATE POLICY "delivery_evidence_delete_owner"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'delivery-evidence'
  AND owner = auth.uid()
);

-- 5. Verificar que el bucket se creó correctamente
SELECT
  id,
  name,
  public,
  created_at
FROM storage.buckets
WHERE id = 'delivery-evidence';
