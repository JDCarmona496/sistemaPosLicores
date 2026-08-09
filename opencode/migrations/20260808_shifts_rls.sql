-- ============================================================================
-- MIGRACIÓN: RLS para que vendedores puedan abrir/cerrar sus propios turnos
-- Fecha: 2026-08-08
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CAJAS: cualquier usuario autenticado puede ver las activas
-- ----------------------------------------------------------------------------
drop policy if exists "Only admins can view cash registers" on public.cash_registers;

create policy "Usuarios autenticados ven cajas activas" on public.cash_registers
  for select to authenticated
  using (is_active = true);

-- ----------------------------------------------------------------------------
-- TURNOS: vendedores abren/cierran los suyos, admins todo
-- ----------------------------------------------------------------------------
drop policy if exists "Only admins can manage shifts" on public.shifts;

-- Ver turnos propios (o todos si es admin)
create policy "Ver turnos propios o todos si es admin" on public.shifts
  for select to authenticated
  using (
    private.is_admin() or auth.uid() = opened_by
  );

-- Crear turnos propios
create policy "Crear turnos propios" on public.shifts
  for insert to authenticated
  with check (
    auth.uid() = opened_by
  );

-- Actualizar solo turnos abiertos propios (cierre de turno)
create policy "Cerrar turnos propios abiertos" on public.shifts
  for update to authenticated
  using (
    status = 'open' and auth.uid() = opened_by
  )
  with check (
    auth.uid() = opened_by
  );

-- ----------------------------------------------------------------------------
-- SEMILLA: caja principal por defecto
-- ----------------------------------------------------------------------------
insert into public.cash_registers (name, description, is_safe, is_active)
select 'Caja Principal', 'Caja principal del punto de venta', false, true
where not exists (select 1 from public.cash_registers);
