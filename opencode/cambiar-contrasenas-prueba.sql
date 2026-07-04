-- ============================================================================
-- CAMBIAR CONTRASEÑAS DE USUARIOS DE PRUEBA
-- ============================================================================
-- Uso:
-- 1. Abre el SQL Editor de Supabase (https://supabase.com/dashboard/project/_/sql)
-- 2. Pega este script.
-- 3. Modifica las contraseñas que desees al inicio de la sección de EJEMPLOS.
-- 4. Ejecuta.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OPCIÓN A: Cambiar la contraseña de TODOS los usuarios de prueba a la misma
-- ----------------------------------------------------------------------------
-- Descomenta el bloque de abajo y ajusta 'NuevaClave123' por la contraseña que quieras.

-- update auth.users
-- set
--   encrypted_password = crypt('NuevaClave123', gen_salt('bf')),
--   updated_at         = now()
-- where email in (
--   'admin@licoreria.com',
--   'vendedor@licoreria.com',
--   'domiciliario@licoreria.com'
-- );

-- ----------------------------------------------------------------------------
-- OPCIÓN B: Cambiar contraseñas individuales por email
-- ----------------------------------------------------------------------------
-- Descomenta y edita cada línea según necesites.

-- update auth.users
-- set encrypted_password = crypt('AdminPass123', gen_salt('bf')), updated_at = now()
-- where email = 'admin@licoreria.com';

-- update auth.users
-- set encrypted_password = crypt('VendedorPass123', gen_salt('bf')), updated_at = now()
-- where email = 'vendedor@licoreria.com';

-- update auth.users
-- set encrypted_password = crypt('DomicilioPass123', gen_salt('bf')), updated_at = now()
-- where email = 'domiciliario@licoreria.com';

-- ----------------------------------------------------------------------------
-- OPCIÓN C: Función reutilizable para cambiar cualquier contraseña por email
-- ----------------------------------------------------------------------------
-- Ejecuta una sola vez para crear la función. Luego usa:
--   select public.change_password('admin@licoreria.com', 'NuevaClaveSegura123');
-- ----------------------------------------------------------------------------

create or replace function public.change_password(
  p_email text,
  p_new_password text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_min_length int := 8;
begin
  -- Validar longitud mínima
  if length(p_new_password) < v_min_length then
    return format('Error: la contraseña debe tener al menos %s caracteres.', v_min_length);
  end if;

  -- Buscar usuario
  select id into v_user_id
  from auth.users
  where email = p_email;

  if v_user_id is null then
    return format('Error: no existe un usuario con el email %s.', p_email);
  end if;

  -- Actualizar contraseña hasheada con bcrypt
  update auth.users
  set
    encrypted_password = crypt(p_new_password, gen_salt('bf')),
    updated_at         = now()
  where id = v_user_id;

  return format('Contraseña actualizada correctamente para %s.', p_email);
end;
$$;

-- Ejemplos de uso (descomenta el que necesites):
-- select public.change_password('admin@licoreria.com', 'NuevaAdmin123');
-- select public.change_password('vendedor@licoreria.com', 'NuevaVendedor123');
-- select public.change_password('domiciliario@licoreria.com', 'NuevaDomicilio123');

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN: Listar usuarios de prueba y confirmar que aún existen
-- ----------------------------------------------------------------------------
select
  u.email,
  u.updated_at,
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
