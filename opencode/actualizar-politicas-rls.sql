-- ============================================================================
-- ACTUALIZAR POLÍTICAS RLS PARA TABLAS DE REFERENCIA
-- ============================================================================
-- Permite acceso público de lectura a tablas de referencia necesarias
-- para el funcionamiento básico de la app (categorías, marcas, cajas)
-- ============================================================================

-- Eliminar políticas existentes para categories
drop policy if exists "Categories are viewable by all" on public.categories;

-- Crear nueva política: acceso público de lectura
create policy "Categories are publicly readable"
  on public.categories for select
  using (true);

-- Eliminar políticas existentes para brands
drop policy if exists "Brands are viewable by all" on public.brands;

-- Crear nueva política: acceso público de lectura
create policy "Brands are publicly readable"
  on public.brands for select
  using (true);

-- Eliminar políticas existentes para cash_registers
drop policy if exists "Only admins can view cash registers" on public.cash_registers;

-- Crear nueva política: acceso público de lectura
create policy "Cash registers are publicly readable"
  on public.cash_registers for select
  using (true);

-- Verificar que las políticas se crearon correctamente
select tablename, policyname, cmd, qual
from pg_policies
where tablename in ('categories', 'brands', 'cash_registers')
  and cmd = 'select';
