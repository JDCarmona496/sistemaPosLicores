-- ============================================================================
-- VERIFICAR COHERENCIA ENTRE auth.users Y public.profiles
-- ============================================================================

-- 1. Usuarios de prueba en auth.users
select
  u.id as user_id,
  u.email,
  u.email_confirmed_at,
  u.encrypted_password = crypt('Test123456', u.encrypted_password) as password_ok,
  u.raw_user_meta_data->>'full_name' as auth_full_name,
  u.raw_user_meta_data->>'role' as auth_role
from auth.users u
where u.email in (
  'admin@licoreria.com',
  'vendedor@licoreria.com',
  'domiciliario@licoreria.com'
)
order by u.email;

-- 2. Relación usuario <-> perfil
select
  u.id as user_id,
  u.email as user_email,
  p.id as profile_id,
  p.email as profile_email,
  (u.id = p.id) as ids_match,
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
