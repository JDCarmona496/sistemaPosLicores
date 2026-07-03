-- ============================================================================
-- DIAGNÓSTICO RÁPIDO (ejecuta esto primero y dime qué devuelve)
-- ============================================================================
-- Este bloque solo lee, no modifica nada.

-- 1. ¿Existe la tabla public.profiles?
select
  schemaname,
  tablename,
  tableowner
from pg_tables
where schemaname = 'public' and tablename = 'profiles';

-- 2. ¿Qué constraints tiene public.profiles?
select
  conname as constraint_name,
  contype as type
from pg_constraint
where conrelid = 'public.profiles'::regclass
order by contype, conname;

-- 3. ¿Qué constraints tiene auth.users en la columna email?
select
  conname as constraint_name,
  contype as type,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'auth.users'::regclass
order by contype, conname;

-- 4. ¿Existen los usuarios de prueba?
select
  id,
  email,
  email_confirmed_at,
  raw_user_meta_data->>'full_name' as full_name,
  raw_user_meta_data->>'role' as role
from auth.users
where email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by email;

-- 5. ¿Existen los perfiles?
select *
from public.profiles
where email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by email;
