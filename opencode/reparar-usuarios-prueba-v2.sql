-- ============================================================================
-- REPARAR USUARIOS DE PRUEBA v2 (sin ON CONFLICT)
-- ============================================================================
-- Ejecuta este script si el anterior dio error 42P10.
-- No usa ON CONFLICT en ninguna tabla; todo se hace con IF/UPDATE/INSERT.
-- ============================================================================

create extension if not exists pgcrypto;

-- ============================================================================
-- 1. ASEGURAR QUE public.profiles EXISTA Y TENGA PK
-- ============================================================================
do $$
begin
  -- Crear tabla profiles si no existe
  create table if not exists public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    email text not null,
    full_name text not null,
    phone text,
    role public.app_role not null default 'seller',
    pin_code text,
    is_active boolean not null default true,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
  );

  -- Asegurar clave primaria (por si la tabla ya existía sin PK)
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.profiles'::regclass and contype = 'p'
  ) then
    alter table public.profiles add primary key (id);
  end if;
end $$;

-- ============================================================================
-- 2. FUNCIÓN AUXILIAR PARA CREAR/ACTUALIZAR USUARIO Y PERFIL
-- ============================================================================
create or replace function public.upsert_test_user(
  p_id uuid,
  p_email text,
  p_password text,
  p_full_name text,
  p_role text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
begin
  -- Convertir rol de forma segura
  begin
    v_role := p_role::public.app_role;
  exception when others then
    v_role := 'seller';
  end;

  -- Actualizar o insertar en auth.users (sin ON CONFLICT)
  if exists (select 1 from auth.users where email = p_email) then
    update auth.users
    set
      id                 = p_id,
      encrypted_password = crypt(p_password, gen_salt('bf')),
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      raw_user_meta_data = jsonb_build_object('full_name', p_full_name, 'role', p_role),
      updated_at         = now()
    where email = p_email;
  else
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
      p_id,
      '00000000-0000-0000-0000-000000000000',
      p_email,
      crypt(p_password, gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      jsonb_build_object('full_name', p_full_name, 'role', p_role),
      'authenticated',
      'authenticated',
      now(),
      now()
    );
  end if;

  -- Actualizar o insertar en public.profiles (sin ON CONFLICT)
  if exists (select 1 from public.profiles where id = p_id) then
    update public.profiles
    set
      email     = p_email,
      full_name = p_full_name,
      role      = v_role,
      is_active = true
    where id = p_id;
  else
    insert into public.profiles (id, email, full_name, role, is_active)
    values (p_id, p_email, p_full_name, v_role, true);
  end if;

  return format('Usuario %s reparado correctamente.', p_email);
end;
$$;

-- ============================================================================
-- 3. REPARAR LOS 3 USUARIOS DE PRUEBA
-- ============================================================================
select public.upsert_test_user(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'admin@licoreria.com',
  'Test123456',
  'Administrador Sistema',
  'admin'
);

select public.upsert_test_user(
  '22222222-2222-2222-2222-222222222222'::uuid,
  'vendedor@licoreria.com',
  'Test123456',
  'Vendedor Principal',
  'seller'
);

select public.upsert_test_user(
  '33333333-3333-3333-3333-333333333333'::uuid,
  'domiciliario@licoreria.com',
  'Test123456',
  'Domiciliario Principal',
  'delivery'
);

-- ============================================================================
-- 4. VERIFICACIÓN FINAL
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
