-- ============================================================================
-- DIAGNÓSTICO Y RESET DE USUARIOS DE PRUEBA
-- ============================================================================
-- Usa este script si al iniciar sesión te aparece "Email o contraseña incorrectos".
-- 1. Ejecuta las consultas de diagnóstico (sección A).
-- 2. Si las contraseñas no coinciden o los usuarios no existen, ejecuta la
--    sección B para resetear las contraseñas y asegurar los perfiles.
-- ============================================================================

-- ============================================================================
-- A. DIAGNÓSTICO: Verificar usuarios y contraseñas
-- ============================================================================

-- A.1 Verificar que los usuarios existen en auth.users
select
  u.id,
  u.email,
  u.email_confirmed_at,
  u.created_at,
  u.updated_at,
  u.raw_user_meta_data->>'full_name' as full_name,
  u.raw_user_meta_data->>'role' as role,
  (u.encrypted_password is not null and u.encrypted_password <> '') as has_password
from auth.users u
where u.email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by u.email;

-- A.2 Verificar que las contraseñas coincidan con 'Test123456'
-- Si 'password_ok' es false, la contraseña almacenada es distinta.
select
  u.email,
  u.encrypted_password = crypt('Test123456', u.encrypted_password) as password_ok,
  length(u.encrypted_password) > 0 as has_hash
from auth.users u
where u.email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by u.email;

-- A.3 Verificar que los perfiles existen en public.profiles
select
  u.email,
  p.id as profile_id,
  p.full_name,
  p.role,
  p.is_active
from auth.users u
left join public.profiles p on u.id = p.id
where u.email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by u.email;

-- ============================================================================
-- B. RESET: Forzar contraseñas y asegurar perfiles
-- ============================================================================
-- Descomenta todo este bloque y ejecuta si el diagnóstico indica problemas.
-- Después de ejecutar, todos los usuarios de prueba tendrán la contraseña:
-- Test123456
-- ============================================================================

/*
-- B.1 Actualizar/resetear contraseñas
update auth.users
set
  encrypted_password = crypt('Test123456', gen_salt('bf')),
  email_confirmed_at = coalesce(email_confirmed_at, now()),
  updated_at         = now()
where email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
);

-- B.2 Asegurar que existan los perfiles (por si el trigger handle_new_user no corrió)
insert into public.profiles (id, email, full_name, role, is_active)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  coalesce((u.raw_user_meta_data->>'role')::public.app_role, 'seller'),
  true
from auth.users u
where u.email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
  and u.id not in (select id from public.profiles)
on conflict (id) do update set
  full_name = excluded.full_name,
  role      = excluded.role,
  is_active = true;
*/

-- ============================================================================
-- C. VERIFICACIÓN FINAL (ejecutar después del reset)
-- ============================================================================
select
  u.email,
  u.encrypted_password = crypt('Test123456', u.encrypted_password) as password_ok,
  p.full_name,
  p.role,
  p.is_active
from auth.users u
left join public.profiles p on u.id = p.id
where u.email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by u.email;
