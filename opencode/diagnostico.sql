-- ============================================================================
-- DIAGNÓSTICO: ¿QUÉ SE CREÓ Y QUÉ FALTA?
-- ============================================================================

-- 1. Verificar tablas creadas
select 
  table_name,
  case 
    when table_name in (
      'profiles', 'brands', 'categories', 'products', 'product_lots',
      'price_history', 'inventory_movements', 'customers', 'customer_baskets',
      'orders', 'order_items', 'payments', 'suppliers', 'supplier_invoices',
      'supplier_invoice_items', 'cash_registers', 'shifts', 'cash_transactions',
      'daily_closings', 'weekly_closings', 'expenses', 'promotions', 'coupons',
      'loyalty_points', 'scheduled_orders', 'scheduled_order_items', 'messages',
      'audit_logs'
    ) then '✅ DEBERÍA EXISTIR'
    else '❓ OTRA TABLA'
  end as estado
from information_schema.tables
where table_schema = 'public'
  and table_type = 'BASE TABLE'
order by 
  case estado 
    when '✅ DEBERÍA EXISTIR' then 1 
    else 2 
  end,
  table_name;

-- 2. Contar tablas del sistema
select 
  count(*) as tablas_creadas,
  28 as tablas_esperadas,
  case 
    when count(*) = 28 then '✅ COMPLETO'
    when count(*) > 0 then '⚠️ PARCIAL - Faltan ' || (28 - count(*)) || ' tablas'
    else '❌ NO SE CREÓ NADA'
  end as estado
from information_schema.tables
where table_schema = 'public'
  and table_type = 'BASE TABLE'
  and table_name in (
    'profiles', 'brands', 'categories', 'products', 'product_lots',
    'price_history', 'inventory_movements', 'customers', 'customer_baskets',
    'orders', 'order_items', 'payments', 'suppliers', 'supplier_invoices',
    'supplier_invoice_items', 'cash_registers', 'shifts', 'cash_transactions',
    'daily_closings', 'weekly_closings', 'expenses', 'promotions', 'coupons',
    'loyalty_points', 'scheduled_orders', 'scheduled_order_items', 'messages',
    'audit_logs'
  );

-- 3. Verificar triggers creados
select 
  trigger_name,
  event_object_table as tabla,
  event_manipulation as evento,
  action_statement
from information_schema.triggers
where trigger_schema = 'public'
order by event_object_table, trigger_name;

-- 4. Contar triggers esperados
select 
  count(*) as triggers_creados,
  case 
    when count(*) >= 10 then '✅ BIEN'
    when count(*) > 0 then '⚠️ FALTAN TRIGGERS'
    else '❌ NO HAY TRIGGERS'
  end as estado
from information_schema.triggers
where trigger_schema = 'public';

-- 5. Verificar funciones creadas
select 
  routine_name,
  routine_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'handle_updated_at',
    'handle_new_user',
    'create_user_with_profile'
  )
order by routine_name;

-- 6. Verificar tipos ENUM creados
select 
  t.typname as nombre_tipo,
  e.enumlabel as valor
from pg_type t
join pg_enum e on t.oid = e.enumtypid
where t.typname in (
  'app_role', 'product_status', 'packaging_type', 'order_status',
  'sale_type', 'delivery_type', 'payment_status', 'payment_method',
  'inventory_movement_type', 'customer_status', 'customer_type',
  'basket_status', 'cash_transaction_type', 'cash_register_status',
  'expense_category', 'supplier_invoice_status', 'message_status',
  'promotion_status', 'discount_type'
)
order by t.typname, e.enumsortorder;

-- 7. Verificar datos iniciales
select 
  'Cajas' as tipo,
  count(*) as cantidad
from cash_registers
union all
select 
  'Categorías',
  count(*)
from categories
union all
select 
  'Marcas',
  count(*)
from brands
union all
select 
  'Productos',
  count(*)
from products
union all
select 
  'Usuarios (profiles)',
  count(*)
from profiles;

-- 8. Verificar RLS habilitado
select 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles', 'products', 'orders', 'customers', 'payments'
  )
order by tablename;

-- 9. Verificar políticas RLS
select 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- ============================================================================
-- RESUMEN EJECUTIVO
-- ============================================================================

select 
  'TABLAS' as componente,
  (select count(*) from information_schema.tables 
   where table_schema = 'public' and table_type = 'BASE TABLE'
   and table_name in ('profiles', 'brands', 'categories', 'products', 'orders', 'customers', 'payments')) as creadas,
  7 as minimas_esperadas,
  case 
    when (select count(*) from information_schema.tables 
          where table_schema = 'public' and table_type = 'BASE TABLE'
          and table_name in ('profiles', 'brands', 'categories', 'products', 'orders', 'customers', 'payments')) >= 7 
    then '✅' else '❌' end as estado
union all
select 
  'TRIGGERS',
  (select count(*) from information_schema.triggers where trigger_schema = 'public'),
  5,
  case 
    when (select count(*) from information_schema.triggers where trigger_schema = 'public') >= 5 
    then '✅' else '❌' end
union all
select 
  'FUNCIONES',
  (select count(*) from information_schema.routines 
   where routine_schema = 'public' and routine_name in ('handle_updated_at', 'handle_new_user')),
  2,
  case 
    when (select count(*) from information_schema.routines 
          where routine_schema = 'public' and routine_name in ('handle_updated_at', 'handle_new_user')) >= 2 
    then '✅' else '❌' end
union all
select 
  'TIPOS ENUM',
  (select count(distinct t.typname) from pg_type t 
   where t.typname in ('app_role', 'product_status', 'order_status', 'payment_method')),
  4,
  case 
    when (select count(distinct t.typname) from pg_type t 
          where t.typname in ('app_role', 'product_status', 'order_status', 'payment_method')) >= 4 
    then '✅' else '❌' end;
