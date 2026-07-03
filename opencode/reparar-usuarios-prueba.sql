-- ============================================================================
-- REPARAR USUARIOS DE PRUEBA (script auto-contenido, versión robusta)
-- ============================================================================
-- Ejecuta este script en el SQL Editor de Supabase si al iniciar sesión
-- aparece "Error al cargar usuario" o "Email o contraseña incorrectos".
--
-- Hace lo siguiente:
-- 1. Asegura la tabla public.profiles y su clave primaria.
-- 2. Crea o actualiza los 3 usuarios de prueba en auth.users.
-- 3. Fuerza la contraseña a: Test123456
-- 4. Confirma el email.
-- 5. Crea o repara los perfiles en public.profiles.
-- ============================================================================

-- Asegurar que la extensión pgcrypto esté disponible
create extension if not exists pgcrypto;

-- ============================================================================
-- 0. ASEGURAR QUE public.profiles TENGA CLAVE PRIMARIA EN id
-- ============================================================================
-- Si el schema no se aplicó correctamente, esta restricción puede faltar y
-- causa el error: "there is no unique or exclusion constraint matching the
-- ON CONFLICT specification".
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and contype = 'p'
  ) then
    alter table public.profiles add primary key (id);
  end if;
end $$;

-- ============================================================================
-- 1. ADMIN
-- ============================================================================
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
)
values (
  '11111111-1111-1111-1111-111111111111',
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
)
on conflict (email) do update set
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at         = now();

-- ============================================================================
-- 2. VENDEDOR
-- ============================================================================
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
)
values (
  '22222222-2222-2222-2222-222222222222',
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
)
on conflict (email) do update set
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at         = now();

-- ============================================================================
-- 3. DOMICILIARIO
-- ============================================================================
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
)
values (
  '33333333-3333-3333-3333-333333333333',
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
)
on conflict (email) do update set
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at         = now();

-- ============================================================================
-- 4. CREAR/REPARAR PERFILES (usando PL/pgSQL para evitar problemas de ON CONFLICT)
-- ============================================================================
do $$
declare
  v_user record;
begin
  for v_user in
    select
      u.id,
      u.email,
      coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)) as full_name,
      coalesce((u.raw_user_meta_data->>'role')::public.app_role, 'seller') as role
    from auth.users u
    where u.email in (
      'admin@licoreria.com',
      'vendedor@licoreria.com',
      'domiciliario@licoreria.com'
    )
  loop
    if exists (select 1 from public.profiles where id = v_user.id) then
      update public.profiles
      set
        email     = v_user.email,
        full_name = v_user.full_name,
        role      = v_user.role,
        is_active = true
      where id = v_user.id;
    else
      insert into public.profiles (id, email, full_name, role, is_active)
      values (v_user.id, v_user.email, v_user.full_name, v_user.role, true);
    end if;
  end loop;
end $$;

-- ============================================================================
-- 5. VERIFICACIÓN FINAL
-- ============================================================================
select
  u.email,
  u.encrypted_password = crypt('Test123456', u.encrypted_password) as password_ok,
  u.email_confirmed_at is not null as email_confirmed,
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
