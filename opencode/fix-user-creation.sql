-- ============================================================================
-- DIAGNÓSTICO Y CORRECCIÓN DE ERROR AL CREAR USUARIOS
-- ============================================================================

-- 1. Verificar si el trigger existe y está funcionando
select
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
from information_schema.triggers
where trigger_name = 'on_auth_user_created';

-- 2. Verificar la función handle_new_user
select
  routine_name,
  routine_definition
from information_schema.routines
where routine_name = 'handle_new_user';

-- 3. Ver logs de errores recientes (si están habilitados)
select * from pg_stat_activity
where state = 'active'
  and query like '%auth.users%'
order by query_start desc
limit 10;

-- 4. Probar crear un usuario manualmente para ver el error específico
-- (Esto te dará el error exacto)
do $$
begin
  insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
  values (
    gen_random_uuid(),
    'test@example.com',
    crypt('Test123!', gen_salt('bf')),
    now(),
    '{"full_name": "Test User", "role": "seller"}'::jsonb
  );
exception when others then
  raise notice 'Error: %', sqlerrm;
end $$;

-- ============================================================================
-- SOLUCIÓN: Corregir la función handle_new_user
-- ============================================================================

-- Eliminar el trigger y la función existentes
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Recrear la función con mejor manejo de errores
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
  -- Log del error para debugging
  raise warning 'Error creating profile for user %: %', new.id, sqlerrm;
  -- Re-lanzar el error para que Supabase lo capture
  raise;
end;
$$;

-- Recrear el trigger
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ============================================================================
-- VERIFICAR QUE LA TABLA PROFILES ESTÉ CORRECTA
-- ============================================================================

-- Ver estructura de la tabla profiles
select
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_name = 'profiles'
order by ordinal_position;

-- Verificar que no haya registros duplicados o problemáticos
select count(*) as total_profiles from public.profiles;

-- Verificar que el RLS esté habilitado
select
  schemaname,
  tablename,
  rowsecurity
from pg_tables
where tablename = 'profiles';

-- ============================================================================
-- MÉTODO ALTERNATIVO: Crear usuarios directamente desde SQL
-- ============================================================================

-- Si el dashboard sigue fallando, podés crear usuarios así:

-- Función helper para crear usuarios con perfil
create or replace function public.create_user_with_profile(
  p_email text,
  p_password text,
  p_full_name text,
  p_role app_role default 'seller'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  -- Crear usuario en auth.users
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_user_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  )
  values (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '',
    jsonb_build_object('full_name', p_full_name, 'role', p_role),
    now(),
    now(),
    '',
    '',
    '',
    ''
  )
  returning id into v_user_id;

  return v_user_id;
end;
$$;

-- Uso:
-- select public.create_user_with_profile(
--   'admin@licoreria.com',
--   'Admin123!',
--   'Administrador',
--   'admin'
-- );

-- select public.create_user_with_profile(
--   'vendedor@licoreria.com',
--   'Vendedor123!',
--   'Juan Vendedor',
--   'seller'
-- );

-- select public.create_user_with_profile(
--   'domiciliario@licoreria.com',
--   'Domiciliario123!',
--   'Pedro Domiciliario',
--   'delivery'
-- );

-- ============================================================================
-- VERIFICACIÓN FINAL
-- ============================================================================

-- Ver todos los usuarios creados
select
  u.id,
  u.email,
  u.email_confirmed_at,
  u.raw_user_meta_data->>'full_name' as full_name,
  u.raw_user_meta_data->>'role' as role,
  p.id as profile_id,
  p.created_at as profile_created
from auth.users u
left join public.profiles p on u.id = p.id
order by u.created_at desc;
