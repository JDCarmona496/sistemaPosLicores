-- ============================================================================
-- FIX: Error "Database error saving new user" al crear usuarios
-- Fecha: 2026-08-09
-- ============================================================================
--
-- El trigger on_auth_user_created puede fallar cuando el perfil se inserta
-- con tipos incompatibles (por ejemplo 'seller' como texto en lugar de
-- app_role). Esta migración re-crea la función de forma segura y agrega
-- un manejo de errores que permite ver el motivo exacto en los logs.
--
-- Pasos para aplicar:
-- 1. Abrir Supabase Dashboard → SQL Editor
-- 2. Pegar y ejecutar todo este script
-- 3. Probar crear un usuario desde la app
-- ============================================================================

-- Eliminar trigger y función existentes si los hay
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Recrear la función con tipos explícitos y mejor manejo de errores
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      split_part(new.email, '@', 1)
    ),
    coalesce(
      (new.raw_user_meta_data->>'role')::app_role,
      'seller'::app_role
    )
  );
  return new;
exception when others then
  -- Log del error exacto para poder diagnosticar desde los logs de Supabase
  raise warning 'Error creating profile for user %: %', new.id, sqlerrm;
  -- Re-lanzar el error para que Supabase lo capture y la app lo muestre
  raise;
end;
$$;

-- Recrear el trigger
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ============================================================================
-- Verificación
-- ============================================================================
-- Comprobar que el trigger existe y apunta a la función corregida
select
  trigger_name,
  event_manipulation,
  action_statement
from information_schema.triggers
where trigger_name = 'on_auth_user_created';
