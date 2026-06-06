-- ============================================================================
-- VERIFICAR Y COMPLETAR USUARIOS DE PRUEBA
-- ============================================================================
-- Verifica si los usuarios y perfiles existen, y crea los perfiles si faltan
-- ============================================================================

-- Verificar usuarios existentes
select 
  u.email,
  u.raw_user_meta_data->>'full_name' as nombre,
  u.raw_user_meta_data->>'role' as rol,
  p.id as perfil_id,
  p.full_name as perfil_nombre,
  p.role as perfil_rol
from auth.users u
left join public.profiles p on u.id = p.id
where u.email in ('admin@licoreria.com', 'vendedor@licoreria.com', 'domiciliario@licoreria.com')
order by u.email;

-- Si los perfiles no existen, crearlos manualmente
-- Descomenta y ejecuta solo si es necesario:

/*
-- Crear perfil admin si no existe
insert into public.profiles (id, email, full_name, role)
select id, email, raw_user_meta_data->>'full_name', (raw_user_meta_data->>'role')::app_role
from auth.users
where email = 'admin@licoreria.com'
  and id not in (select id from public.profiles);

-- Crear perfil vendedor si no existe
insert into public.profiles (id, email, full_name, role)
select id, email, raw_user_meta_data->>'full_name', (raw_user_meta_data->>'role')::app_role
from auth.users
where email = 'vendedor@licoreria.com'
  and id not in (select id from public.profiles);

-- Crear perfil domiciliario si no existe
insert into public.profiles (id, email, full_name, role)
select id, email, raw_user_meta_data->>'full_name', (raw_user_meta_data->>'role')::app_role
from auth.users
where email = 'domiciliario@licoreria.com'
  and id not in (select id from public.profiles);
*/
