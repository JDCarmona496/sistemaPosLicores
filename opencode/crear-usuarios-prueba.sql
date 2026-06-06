-- ============================================================================
-- CREAR USUARIOS DE PRUEBA - LICORERÍA
-- ============================================================================
-- Este script crea 3 usuarios de prueba con diferentes roles:
-- - admin@licoreria.com (Administrador)
-- - vendedor@licoreria.com (Vendedor)
-- - domiciliario@licoreria.com (Domiciliario)
--
-- Password para todos: Test123456
-- ============================================================================

-- Crear usuario admin
insert into auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  created_at,
  updated_at
) values (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'admin@licoreria.com',
  crypt('Test123456', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Administrador Sistema", "role": "admin"}',
  'authenticated',
  'authenticated',
  now(),
  now()
);

-- Crear usuario vendedor
insert into auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  created_at,
  updated_at
) values (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'vendedor@licoreria.com',
  crypt('Test123456', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Vendedor Principal", "role": "seller"}',
  'authenticated',
  'authenticated',
  now(),
  now()
);

-- Crear usuario domiciliario
insert into auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  created_at,
  updated_at
) values (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'domiciliario@licoreria.com',
  crypt('Test123456', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Domiciliario Principal", "role": "delivery"}',
  'authenticated',
  'authenticated',
  now(),
  now()
);

-- Verificar usuarios creados
select 
  u.email,
  p.full_name,
  p.role,
  p.is_active,
  u.created_at
from auth.users u
left join public.profiles p on u.id = p.id
where u.email in ('admin@licoreria.com', 'vendedor@licoreria.com', 'domiciliario@licoreria.com')
order by u.email;
