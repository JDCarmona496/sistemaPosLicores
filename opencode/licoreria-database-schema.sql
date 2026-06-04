-- ============================================================================
-- SISTEMA DE GESTIÓN PARA LICORERÍA - BASE DE DATOS SUPABASE
-- ============================================================================
-- Autor: Sistema Licorería
-- Fecha: 2026-06-02
-- Descripción: Schema completo para gestión de licorería con control de
--              inventario, ventas, clientes, proveedores y financiero
-- ============================================================================

-- ============================================================================
-- EXTENSIONES
-- ============================================================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================================
-- SCHEMAS PRIVADOS (para funciones de seguridad)
-- ============================================================================
create schema if not exists private;

-- ============================================================================
-- TIPOS ENUMERADOS
-- ============================================================================

-- Roles de usuario
create type public.app_role as enum ('admin', 'seller', 'delivery');

-- Estados de productos
create type public.product_status as enum ('active', 'out_of_stock', 'discontinued');

-- Tipos de empaque
create type public.packaging_type as enum (
  'unit',           -- unidad
  'sixpack',        -- sixpack (x6)
  'basket',         -- canasta (x13, x16, x30)
  'pack',           -- paca (x12, x15, x24)
  'box',            -- caja (x12, x24)
  'pack_cigarettes', -- cajetilla (x20)
  'half_pack'       -- media (x10)
);

-- Estados de pedidos
create type public.order_status as enum (
  'pending',        -- pendiente
  'preparing',      -- en preparación
  'ready',          -- listo
  'in_transit',     -- en camino (domicilio)
  'delivered',      -- entregado
  'partially_delivered', -- parcialmente entregado
  'cancelled',      -- cancelado
  'returned'        -- devuelto
);

-- Tipos de venta
create type public.sale_type as enum ('cash', 'credit');

-- Tipos de entrega
create type public.delivery_type as enum ('in_store', 'delivery');

-- Estados de pagos
create type public.payment_status as enum ('pending', 'completed', 'failed', 'refunded');

-- Métodos de pago
create type public.payment_method as enum (
  'cash',           -- efectivo
  'nequi',          -- nequi
  'daviplata',      -- daviplata
  'transfer',       -- transferencia
  'card',           -- tarjeta
  'credit'          -- crédito (queda en saldo)
);

-- Tipos de movimiento de inventario
create type public.inventory_movement_type as enum (
  'purchase',       -- compra a proveedor
  'sale',           -- venta
  'return_in',      -- devolución de cliente
  'return_out',     -- devolución a proveedor
  'adjustment_plus', -- ajuste positivo
  'adjustment_minus', -- ajuste negativo
  'damage',         -- daño/merma
  'expired',        -- vencido
  'internal_use'    -- consumo interno
);

-- Estados de clientes
create type public.customer_status as enum ('active', 'inactive', 'blocked');

-- Tipos de cliente
create type public.customer_type as enum (
  'occasional',     -- ocasional
  'frequent',       -- frecuente
  'wholesale',      -- mayorista
  'credit',         -- crédito
  'consignment'     -- consignatario
);

-- Estados de canastas retornables
create type public.basket_status as enum ('outstanding', 'returned', 'charged', 'deposit_held');

-- Tipos de transacción de caja
create type public.cash_transaction_type as enum ('income', 'expense');

-- Estados de caja
create type public.cash_register_status as enum ('open', 'closed');

-- Tipos de gasto
create type public.expense_category as enum (
  'utilities',      -- servicios
  'maintenance',    -- mantenimiento
  'supplies',       -- insumos
  'transport',      -- transporte
  'other'           -- otros
);

-- Estados de facturas de proveedor
create type public.supplier_invoice_status as enum ('pending', 'partial', 'paid', 'overdue');

-- Estados de mensajes internos
create type public.message_status as enum ('sent', 'read');

-- Estados de promociones
create type public.promotion_status as enum ('active', 'inactive', 'expired');

-- Tipos de descuento
create type public.discount_type as enum ('percentage', 'fixed_amount');

-- ============================================================================
-- TABLA: PROFILES (Extensión de auth.users)
-- ============================================================================
-- Almacena información adicional de cada usuario del sistema
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text not null,
  full_name text not null,
  phone text,
  role app_role not null default 'seller',
  pin_code text, -- PIN de 4 dígitos para acceso rápido (hash)
  is_active boolean not null default true,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Perfiles de usuario extendidos desde auth.users';
comment on column public.profiles.pin_code is 'PIN de 4 dígitos hasheado para acceso rápido';

-- Índices
create index idx_profiles_role on public.profiles(role);
create index idx_profiles_active on public.profiles(is_active) where is_active = true;

-- Trigger para actualizar updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_profile_updated
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- Trigger para crear profile automáticamente al registrar usuario
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data->>'role')::app_role, 'seller')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- TABLA: BRANDS (Marcas)
-- ============================================================================
create table public.brands (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  slug text not null unique,
  description text,
  logo_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.brands is 'Marcas de productos';

create index idx_brands_active on public.brands(is_active) where is_active = true;
create trigger on_brand_updated
  before update on public.brands
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: CATEGORIES (Categorías)
-- ============================================================================
create table public.categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  slug text not null unique,
  description text,
  parent_id uuid references public.categories(id) on delete set null,
  icon_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.categories is 'Categorías de productos (jerárquicas)';

create index idx_categories_parent on public.categories(parent_id);
create index idx_categories_active on public.categories(is_active) where is_active = true;
create trigger on_category_updated
  before update on public.categories
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: PRODUCTS (Productos)
-- ============================================================================
create table public.products (
  id uuid primary key default uuid_generate_v4(),
  code integer not null unique, -- código interno (1000, 1001, etc.)
  barcode text unique, -- código de barras EAN/UPC (nullable por ahora)
  brand_id uuid not null references public.brands(id) on delete restrict,
  category_id uuid not null references public.categories(id) on delete restrict,
  name text not null, -- nombre descriptivo
  description text,
  presentation text not null, -- 330ml, 750ml, 1000ml, cajetilla, media
  volume_ml integer, -- volumen en ml para cálculos (nullable para cajetillas, etc.)
  packaging_type packaging_type not null,
  units_per_package integer not null default 1, -- 1, 6, 13, 16, 24, 30, etc.
  is_cold boolean not null default false, -- producto frío
  is_returnable boolean not null default false, -- envase retornable (canastas)
  returnable_deposit numeric(12,2) default 0, -- valor del envase retornable
  price_retail numeric(12,2) not null, -- precio al detal
  price_wholesale numeric(12,2) not null, -- precio al por mayor
  price_wholesale_fractional numeric(12,2), -- precio mayorista fraccionado por unidad
  cost numeric(12,2) not null default 0, -- costo de compra (para rentabilidad)
  stock_current integer not null default 0, -- stock actual
  stock_min integer not null default 5, -- stock mínimo
  stock_max integer not null default 100, -- stock máximo
  status product_status not null default 'active',
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.products is 'Catálogo de productos';
comment on column public.products.price_wholesale_fractional is 'Precio mayorista por unidad cuando se vende fraccionado (ej: media canasta)';

-- Índices
create index idx_products_code on public.products(code);
create index idx_products_barcode on public.products(barcode) where barcode is not null;
create index idx_products_brand on public.products(brand_id);
create index idx_products_category on public.products(category_id);
create index idx_products_status on public.products(status) where status = 'active';
create index idx_products_cold on public.products(is_cold) where is_cold = true;
create index idx_products_returnable on public.products(is_returnable) where is_returnable = true;

-- Trigger updated_at
create trigger on_product_updated
  before update on public.products
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: PRODUCT_LOTS (Control de Lotes y Vencimientos)
-- ============================================================================
create table public.product_lots (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references public.products(id) on delete cascade,
  lot_number text not null,
  supplier_id uuid, -- referencia a suppliers (se agregará después)
  quantity integer not null,
  quantity_remaining integer not null,
  cost_unit numeric(12,2) not null,
  expiration_date date,
  received_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

comment on table public.product_lots is 'Control de lotes y vencimientos por producto';

create index idx_product_lots_product on public.product_lots(product_id);
create index idx_product_lots_expiration on public.product_lots(expiration_date) where expiration_date is not null;
create index idx_product_lots_remaining on public.product_lots(quantity_remaining) where quantity_remaining > 0;

-- ============================================================================
-- TABLA: PRICE_HISTORY (Historial de Cambios de Precios)
-- ============================================================================
create table public.price_history (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references public.products(id) on delete cascade,
  changed_by uuid not null references public.profiles(id) on delete restrict,
  price_retail_old numeric(12,2),
  price_retail_new numeric(12,2),
  price_wholesale_old numeric(12,2),
  price_wholesale_new numeric(12,2),
  reason text,
  created_at timestamptz not null default now()
);

comment on table public.price_history is 'Historial de cambios de precios';

create index idx_price_history_product on public.price_history(product_id);
create index idx_price_history_date on public.price_history(created_at desc);

-- ============================================================================
-- TABLA: INVENTORY_MOVEMENTS (Movimientos de Inventario)
-- ============================================================================
create table public.inventory_movements (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references public.products(id) on delete restrict,
  movement_type inventory_movement_type not null,
  quantity integer not null, -- positivo para entradas, negativo para salidas
  reference_id uuid, -- ID del pedido, factura de proveedor, etc.
  reference_type text, -- 'order', 'supplier_invoice', 'adjustment', etc.
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

comment on table public.inventory_movements is 'Todos los movimientos de inventario';

create index idx_inventory_movements_product on public.inventory_movements(product_id);
create index idx_inventory_movements_type on public.inventory_movements(movement_type);
create index idx_inventory_movements_date on public.inventory_movements(created_at desc);
create index idx_inventory_movements_reference on public.inventory_movements(reference_id, reference_type);

-- ============================================================================
-- TABLA: CUSTOMERS (Clientes)
-- ============================================================================
create table public.customers (
  id uuid primary key default uuid_generate_v4(),
  identification text unique, -- cédula o NIT
  full_name text not null,
  phone text not null,
  email text,
  address text,
  latitude numeric(10,8), -- coordenadas GPS
  longitude numeric(11,8),
  customer_type customer_type not null default 'occasional',
  status customer_status not null default 'active',
  credit_limit numeric(12,2) default 0, -- límite de crédito
  current_balance numeric(12,2) not null default 0, -- saldo actual (deuda)
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.customers is 'Clientes del negocio';
comment on column public.customers.current_balance is 'Saldo actual de deudas (para clientes a crédito)';

create index idx_customers_identification on public.customers(identification);
create index idx_customers_phone on public.customers(phone);
create index idx_customers_type on public.customers(customer_type);
create index idx_customers_status on public.customers(status) where status = 'active';
create index idx_customers_balance on public.customers(current_balance) where current_balance > 0;

create trigger on_customer_updated
  before update on public.customers
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: CUSTOMER_BASKETS (Control de Canastas Retornables)
-- ============================================================================
create table public.customer_baskets (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity_out integer not null, -- canastas que salieron
  quantity_returned integer not null default 0, -- canastas devueltas
  deposit_amount numeric(12,2) default 0, -- depósito en efectivo retenido
  status basket_status not null default 'outstanding',
  order_id uuid, -- referencia al pedido (se agregará FK después)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  returned_at timestamptz
);

comment on table public.customer_baskets is 'Control de canastas retornables por cliente';

create index idx_customer_baskets_customer on public.customer_baskets(customer_id);
create index idx_customer_baskets_product on public.customer_baskets(product_id);
create index idx_customer_baskets_status on public.customer_baskets(status) where status = 'outstanding';

create trigger on_customer_basket_updated
  before update on public.customer_baskets
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: ORDERS (Pedidos/Ventas)
-- ============================================================================
create table public.orders (
  id uuid primary key default uuid_generate_v4(),
  order_number integer not null unique, -- número consecutivo de pedido
  customer_id uuid references public.customers(id) on delete set null,
  seller_id uuid not null references public.profiles(id) on delete restrict,
  delivery_person_id uuid references public.profiles(id) on delete set null,
  status order_status not null default 'pending',
  sale_type sale_type not null default 'cash',
  delivery_type delivery_type not null default 'in_store',
  subtotal numeric(12,2) not null default 0,
  discount_amount numeric(12,2) not null default 0,
  tax_amount numeric(12,2) not null default 0,
  delivery_fee numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  notes text,
  delivery_address text,
  delivery_latitude numeric(10,8),
  delivery_longitude numeric(11,8),
  delivery_photo_url text, -- foto de entrega
  delivery_signature text, -- firma digital (base64 o URL)
  delivered_at timestamptz,
  cancelled_reason text,
  cancelled_by uuid references public.profiles(id) on delete set null,
  cancelled_at timestamptz,
  edit_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.orders is 'Pedidos/ventas del negocio';
comment on column public.orders.order_number is 'Número consecutivo de pedido para facturación';

create index idx_orders_number on public.orders(order_number);
create index idx_orders_customer on public.orders(customer_id);
create index idx_orders_seller on public.orders(seller_id);
create index idx_orders_delivery_person on public.orders(delivery_person_id);
create index idx_orders_status on public.orders(status);
create index idx_orders_sale_type on public.orders(sale_type);
create index idx_orders_date on public.orders(created_at desc);
create index idx_orders_delivered on public.orders(delivered_at) where delivered_at is not null;

create trigger on_order_updated
  before update on public.orders
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: ORDER_ITEMS (Items del Pedido)
-- ============================================================================
create table public.order_items (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity numeric(10,2) not null, -- cantidad (puede ser decimal para fraccionado)
  quantity_delivered numeric(10,2) not null default 0, -- cantidad entregada (para entregas parciales)
  unit_price numeric(12,2) not null, -- precio unitario aplicado
  discount_amount numeric(12,2) not null default 0,
  subtotal numeric(12,2) not null, -- quantity * unit_price - discount
  is_wholesale_price boolean not null default false, -- se aplicó precio mayorista
  notes text,
  delivered_at timestamptz, -- fecha/hora de entrega de este item
  created_at timestamptz not null default now()
);

comment on table public.order_items is 'Items/productos en cada pedido';

create index idx_order_items_order on public.order_items(order_id);
create index idx_order_items_product on public.order_items(product_id);

-- ============================================================================
-- TABLA: ORDER_EDITS (Historial de Ediciones de Pedidos)
-- ============================================================================
create table public.order_edits (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  edited_by uuid not null references public.profiles(id) on delete restrict,
  edit_type text not null, -- 'add_item', 'remove_item', 'change_quantity', 'change_customer', 'change_delivery', 'change_payment', 'change_notes'
  field_changed text, -- campo específico que se modificó
  old_value jsonb, -- valor anterior
  new_value jsonb, -- valor nuevo
  reason text, -- motivo de la edición
  created_at timestamptz not null default now()
);

comment on table public.order_edits is 'Historial completo de ediciones de pedidos';

create index idx_order_edits_order on public.order_edits(order_id);
create index idx_order_edits_by on public.order_edits(edited_by);
create index idx_order_edits_date on public.order_edits(created_at desc);

-- ============================================================================
-- TABLA: ORDER_ITEM_CANCELLATIONS (Cancelaciones Parciales de Items)
-- ============================================================================
create table public.order_item_cancellations (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  order_item_id uuid not null references public.order_items(id) on delete cascade,
  cancelled_by uuid not null references public.profiles(id) on delete restrict,
  quantity_cancelled numeric(10,2) not null, -- cantidad cancelada
  reason text not null, -- motivo de cancelación
  stock_restored boolean not null default true, -- si se restauró el stock
  created_at timestamptz not null default now()
);

comment on table public.order_item_cancellations is 'Registro de cancelaciones parciales de items en pedidos';

create index idx_oic_order on public.order_item_cancellations(order_id);
create index idx_oic_item on public.order_item_cancellations(order_item_id);
create index idx_oic_date on public.order_item_cancellations(created_at desc);

-- ============================================================================
-- TABLA: ORDER_REMINDERS (Recordatorios de Pedidos Pendientes)
-- ============================================================================
create table public.order_reminders (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  reminder_type text not null, -- 'delayed', 'partial_delivery', 'urgent', 'daily_summary'
  sent_to uuid not null references public.profiles(id) on delete cascade, -- a quién se envió
  sent_at timestamptz not null default now(),
  acknowledged boolean not null default false, -- si fue visto/confirmado
  acknowledged_at timestamptz,
  message text not null, -- texto del recordatorio
  priority integer not null default 1, -- 1=normal, 2=alta, 3=urgente
  metadata jsonb -- datos adicionales (tiempo transcurrido, productos pendientes, etc.)
);

comment on table public.order_reminders is 'Recordatorios automáticos de pedidos pendientes y entregas parciales';

create index idx_order_reminders_order on public.order_reminders(order_id);
create index idx_order_reminders_sent_to on public.order_reminders(sent_to);
create index idx_order_reminders_ack on public.order_reminders(acknowledged) where acknowledged = false;
create index idx_order_reminders_priority on public.order_reminders(priority desc, sent_at desc);
create index idx_order_reminders_date on public.order_reminders(sent_at desc);

-- ============================================================================
-- TABLA: PAYMENTS (Pagos)
-- ============================================================================
create table public.payments (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid references public.orders(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete cascade, -- para abonos a crédito
  payment_method payment_method not null,
  amount numeric(12,2) not null,
  reference text, -- número de transacción, referencia bancaria, etc.
  status payment_status not null default 'completed',
  received_by uuid not null references public.profiles(id) on delete restrict,
  notes text,
  created_at timestamptz not null default now()
);

comment on table public.payments is 'Pagos de pedidos y abonos a crédito';

create index idx_payments_order on public.payments(order_id);
create index idx_payments_customer on public.payments(customer_id);
create index idx_payments_method on public.payments(payment_method);
create index idx_payments_date on public.payments(created_at desc);

-- ============================================================================
-- TABLA: SUPPLIERS (Proveedores)
-- ============================================================================
create table public.suppliers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  nit text unique,
  contact_name text,
  phone text not null,
  email text,
  address text,
  payment_terms text, -- 'contado', '30 días', etc.
  credit_limit numeric(12,2) default 0,
  current_balance numeric(12,2) not null default 0, -- saldo pendiente
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.suppliers is 'Proveedores del negocio';

create index idx_suppliers_name on public.suppliers(name);
create index idx_suppliers_active on public.suppliers(is_active) where is_active = true;
create index idx_suppliers_balance on public.suppliers(current_balance) where current_balance > 0;

create trigger on_supplier_updated
  before update on public.suppliers
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: SUPPLIER_INVOICES (Facturas de Proveedores)
-- ============================================================================
create table public.supplier_invoices (
  id uuid primary key default uuid_generate_v4(),
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  invoice_number text not null,
  invoice_date date not null,
  due_date date, -- fecha de vencimiento (para crédito)
  subtotal numeric(12,2) not null,
  tax_amount numeric(12,2) not null default 0,
  total numeric(12,2) not null,
  paid_amount numeric(12,2) not null default 0,
  status supplier_invoice_status not null default 'pending',
  payment_type sale_type not null, -- contado o crédito
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(supplier_id, invoice_number)
);

comment on table public.supplier_invoices is 'Facturas de compra a proveedores';

create index idx_supplier_invoices_supplier on public.supplier_invoices(supplier_id);
create index idx_supplier_invoices_status on public.supplier_invoices(status);
create index idx_supplier_invoices_due_date on public.supplier_invoices(due_date) where due_date is not null;

create trigger on_supplier_invoice_updated
  before update on public.supplier_invoices
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: SUPPLIER_INVOICE_ITEMS (Items de Facturas de Proveedor)
-- ============================================================================
create table public.supplier_invoice_items (
  id uuid primary key default uuid_generate_v4(),
  supplier_invoice_id uuid not null references public.supplier_invoices(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity integer not null,
  unit_cost numeric(12,2) not null,
  subtotal numeric(12,2) not null,
  lot_number text,
  expiration_date date,
  created_at timestamptz not null default now()
);

comment on table public.supplier_invoice_items is 'Items en facturas de proveedor';

create index idx_supplier_invoice_items_invoice on public.supplier_invoice_items(supplier_invoice_id);
create index idx_supplier_invoice_items_product on public.supplier_invoice_items(product_id);

-- ============================================================================
-- TABLA: CASH_REGISTERS (Cajas)
-- ============================================================================
create table public.cash_registers (
  id uuid primary key default uuid_generate_v4(),
  name text not null, -- 'Caja Principal', 'Caja Fuerte', etc.
  description text,
  is_safe boolean not null default false, -- true = caja fuerte
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.cash_registers is 'Cajas del negocio (principal, fuerte, etc.)';

-- ============================================================================
-- TABLA: SHIFTS (Turnos)
-- ============================================================================
create table public.shifts (
  id uuid primary key default uuid_generate_v4(),
  cash_register_id uuid not null references public.cash_registers(id) on delete restrict,
  opened_by uuid not null references public.profiles(id) on delete restrict,
  closed_by uuid references public.profiles(id) on delete set null,
  status cash_register_status not null default 'open',
  opening_amount numeric(12,2) not null default 0, -- monto inicial
  closing_amount numeric(12,2), -- monto final contado
  expected_amount numeric(12,2), -- monto esperado según ventas
  difference numeric(12,2), -- diferencia (sobrante/faltante)
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  notes text
);

comment on table public.shifts is 'Turnos de trabajo con apertura y cierre de caja';

create index idx_shifts_register on public.shifts(cash_register_id);
create index idx_shifts_status on public.shifts(status) where status = 'open';
create index idx_shifts_opened_by on public.shifts(opened_by);
create index idx_shifts_date on public.shifts(opened_at desc);

-- ============================================================================
-- TABLA: CASH_TRANSACTIONS (Transacciones de Caja)
-- ============================================================================
create table public.cash_transactions (
  id uuid primary key default uuid_generate_v4(),
  shift_id uuid not null references public.shifts(id) on delete cascade,
  cash_register_id uuid not null references public.cash_registers(id) on delete restrict,
  transaction_type cash_transaction_type not null,
  amount numeric(12,2) not null,
  payment_method payment_method not null,
  reference_id uuid, -- ID del pedido, factura, gasto, etc.
  reference_type text, -- 'order', 'supplier_invoice', 'expense', etc.
  description text not null,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

comment on table public.cash_transactions is 'Todas las transacciones de caja';

create index idx_cash_transactions_shift on public.cash_transactions(shift_id);
create index idx_cash_transactions_register on public.cash_transactions(cash_register_id);
create index idx_cash_transactions_type on public.cash_transactions(transaction_type);
create index idx_cash_transactions_date on public.cash_transactions(created_at desc);

-- ============================================================================
-- TABLA: DAILY_CLOSINGS (Cierres Diarios)
-- ============================================================================
create table public.daily_closings (
  id uuid primary key default uuid_generate_v4(),
  closing_date date not null unique,
  closed_by uuid not null references public.profiles(id) on delete restrict,
  total_sales numeric(12,2) not null default 0,
  total_cash numeric(12,2) not null default 0,
  total_nequi numeric(12,2) not null default 0,
  total_transfer numeric(12,2) not null default 0,
  total_credit numeric(12,2) not null default 0,
  total_expenses numeric(12,2) not null default 0,
  total_supplier_payments numeric(12,2) not null default 0,
  cash_counted numeric(12,2), -- dinero contado físicamente
  cash_expected numeric(12,2), -- dinero esperado según sistema
  difference numeric(12,2), -- diferencia
  notes text,
  created_at timestamptz not null default now()
);

comment on table public.daily_closings is 'Cierres de caja diarios';

create index idx_daily_closings_date on public.daily_closings(closing_date desc);

-- ============================================================================
-- TABLA: WEEKLY_CLOSINGS (Cierres Semanales)
-- ============================================================================
create table public.weekly_closings (
  id uuid primary key default uuid_generate_v4(),
  week_start date not null,
  week_end date not null,
  closed_by uuid not null references public.profiles(id) on delete restrict,
  total_sales numeric(12,2) not null default 0,
  total_expenses numeric(12,2) not null default 0,
  total_supplier_payments numeric(12,2) not null default 0,
  total_payroll numeric(12,2) not null default 0, -- nóminas
  total_rent numeric(12,2) not null default 0, -- alquiler
  total_utilities numeric(12,2) not null default 0, -- servicios
  total_other_payments numeric(12,2) not null default 0,
  total_credit_collections numeric(12,2) not null default 0, -- abonos recibidos
  safe_balance numeric(12,2), -- saldo de caja fuerte
  notes text,
  created_at timestamptz not null default now(),
  unique(week_start, week_end)
);

comment on table public.weekly_closings is 'Cierres semanales con pagos fijos';

create index idx_weekly_closings_dates on public.weekly_closings(week_start desc);

-- ============================================================================
-- TABLA: EXPENSES (Gastos Diarios)
-- ============================================================================
create table public.expenses (
  id uuid primary key default uuid_generate_v4(),
  shift_id uuid references public.shifts(id) on delete set null,
  category expense_category not null,
  amount numeric(12,2) not null,
  description text not null,
  receipt_photo_url text,
  paid_from_safe boolean not null default false, -- true = de caja fuerte
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

comment on table public.expenses is 'Gastos diarios del negocio';

create index idx_expenses_category on public.expenses(category);
create index idx_expenses_date on public.expenses(created_at desc);
create index idx_expenses_shift on public.expenses(shift_id);

-- ============================================================================
-- TABLA: PROMOTIONS (Promociones)
-- ============================================================================
create table public.promotions (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  promotion_type text not null, -- 'percentage', 'fixed', 'bundle', 'buy_x_get_y'
  discount_type discount_type,
  discount_value numeric(12,2), -- porcentaje o monto fijo
  min_quantity integer, -- cantidad mínima para aplicar
  min_amount numeric(12,2), -- monto mínimo para aplicar
  applicable_products uuid[], -- array de product_ids (null = todos)
  applicable_categories uuid[], -- array de category_ids
  excluded_products uuid[], -- productos excluidos
  valid_from date not null,
  valid_until date,
  valid_days integer[], -- [1,2,3,4,5,6,7] = lunes a domingo
  valid_from_time time, -- hora inicio (para happy hour)
  valid_until_time time, -- hora fin
  max_uses integer, -- límite total de usos
  max_uses_per_customer integer,
  current_uses integer not null default 0,
  status promotion_status not null default 'active',
  priority integer not null default 0, -- prioridad cuando aplican varias
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.promotions is 'Promociones y descuentos automáticos';

create index idx_promotions_status on public.promotions(status) where status = 'active';
create index idx_promotions_dates on public.promotions(valid_from, valid_until);

create trigger on_promotion_updated
  before update on public.promotions
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- TABLA: COUPONS (Cupones de Descuento)
-- ============================================================================
create table public.coupons (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  description text,
  discount_type discount_type not null,
  discount_value numeric(12,2) not null,
  min_amount numeric(12,2) default 0,
  max_uses integer,
  max_uses_per_customer integer default 1,
  current_uses integer not null default 0,
  valid_from timestamptz not null,
  valid_until timestamptz not null,
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

comment on table public.coupons is 'Cupones de descuento con código';

create index idx_coupons_code on public.coupons(code);
create index idx_coupons_active on public.coupons(is_active) where is_active = true;

-- ============================================================================
-- TABLA: LOYALTY_POINTS (Puntos de Lealtad)
-- ============================================================================
create table public.loyalty_points (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  points_earned integer, -- puntos ganados
  points_redeemed integer, -- puntos canjeados
  points_balance integer not null, -- saldo después de la transacción
  description text,
  created_at timestamptz not null default now()
);

comment on table public.loyalty_points is 'Historial de puntos de lealtad por cliente';

create index idx_loyalty_points_customer on public.loyalty_points(customer_id);
create index idx_loyalty_points_date on public.loyalty_points(created_at desc);

-- ============================================================================
-- TABLA: SCHEDULED_ORDERS (Pedidos Programados)
-- ============================================================================
create table public.scheduled_orders (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  recurrence_type text not null, -- 'daily', 'weekly', 'monthly'
  recurrence_days integer[], -- días de la semana [1,3,5] = lun, mié, vie
  recurrence_time time not null,
  next_delivery_date date not null,
  is_active boolean not null default true,
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.scheduled_orders is 'Pedidos recurrentes programados';

create index idx_scheduled_orders_customer on public.scheduled_orders(customer_id);
create index idx_scheduled_orders_next on public.scheduled_orders(next_delivery_date) where is_active = true;

-- ============================================================================
-- TABLA: SCHEDULED_ORDER_ITEMS (Items de Pedidos Programados)
-- ============================================================================
create table public.scheduled_order_items (
  id uuid primary key default uuid_generate_v4(),
  scheduled_order_id uuid not null references public.scheduled_orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity numeric(10,2) not null,
  created_at timestamptz not null default now()
);

create index idx_scheduled_order_items_order on public.scheduled_order_items(scheduled_order_id);

-- ============================================================================
-- TABLA: MESSAGES (Mensajería Interna)
-- ============================================================================
create table public.messages (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid references public.orders(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  message text not null,
  status message_status not null default 'sent',
  created_at timestamptz not null default now(),
  read_at timestamptz
);

comment on table public.messages is 'Mensajería interna entre usuarios';

create index idx_messages_order on public.messages(order_id);
create index idx_messages_sender on public.messages(sender_id);
create index idx_messages_recipient on public.messages(recipient_id);
create index idx_messages_status on public.messages(status) where status = 'sent';

-- ============================================================================
-- TABLA: AUDIT_LOGS (Logs de Auditoría)
-- ============================================================================
create table public.audit_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete restrict,
  action text not null, -- 'create', 'update', 'delete', 'login', etc.
  table_name text not null,
  record_id uuid,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now()
);

comment on table public.audit_logs is 'Log de auditoría de todas las acciones críticas';

create index idx_audit_logs_user on public.audit_logs(user_id);
create index idx_audit_logs_action on public.audit_logs(action);
create index idx_audit_logs_table on public.audit_logs(table_name);
create index idx_audit_logs_date on public.audit_logs(created_at desc);

-- ============================================================================
-- AGREGAR FK FALTANTES (después de crear todas las tablas)
-- ============================================================================

-- Agregar FK a product_lots.supplier_id
alter table public.product_lots
  add constraint fk_product_lots_supplier
  foreign key (supplier_id) references public.suppliers(id) on delete set null;

-- Agregar FK a customer_baskets.order_id
alter table public.customer_baskets
  add constraint fk_customer_baskets_order
  foreign key (order_id) references public.orders(id) on delete set null;

-- ============================================================================
-- FUNCIONES DE SEGURIDAD (Schema Privado)
-- ============================================================================

-- Función para obtener el rol del usuario actual
create or replace function private.get_current_user_role()
returns app_role
language sql
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- Función para verificar si el usuario es admin
create or replace function private.is_admin()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Función para verificar si el usuario es seller o admin
create or replace function private.is_seller_or_admin()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('seller', 'admin')
  );
$$;

-- Función para registrar auditoría automáticamente
create or replace function private.log_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_logs (user_id, action, table_name, record_id, old_values, new_values)
  values (
    auth.uid(),
    tg_op,
    tg_table_name,
    coalesce(
      case when tg_op = 'INSERT' then new.id else old.id end,
      gen_random_uuid()
    ),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end
  );
  return coalesce(new, old);
end;
$$;

-- ============================================================================
-- TRIGGERS DE AUDITORÍA (para tablas críticas)
-- ============================================================================

create trigger audit_products
  after insert or update or delete on public.products
  for each row execute function private.log_audit();

create trigger audit_orders
  after insert or update or delete on public.orders
  for each row execute function private.log_audit();

create trigger audit_customers
  after insert or update or delete on public.customers
  for each row execute function private.log_audit();

create trigger audit_inventory_movements
  after insert on public.inventory_movements
  for each row execute function private.log_audit();

create trigger audit_payments
  after insert on public.payments
  for each row execute function private.log_audit();

-- ============================================================================
-- FUNCIÓN: Actualizar stock automáticamente
-- ============================================================================
create or replace function private.update_product_stock()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product_id uuid;
  v_quantity_change integer;
begin
  -- Determinar el cambio de stock según el tipo de movimiento
  v_product_id := new.product_id;

  case new.movement_type
    when 'purchase', 'return_in', 'adjustment_plus' then
      v_quantity_change := new.quantity;
    when 'sale', 'return_out', 'adjustment_minus', 'damage', 'expired', 'internal_use' then
      v_quantity_change := -new.quantity;
  end case;

  -- Actualizar stock
  update public.products
  set stock_current = stock_current + v_quantity_change
  where id = v_product_id;

  return new;
end;
$$;

create trigger on_inventory_movement
  after insert on public.inventory_movements
  for each row execute function private.update_product_stock();

-- ============================================================================
-- FUNCIÓN: Actualizar saldo de cliente automáticamente
-- ============================================================================
create or replace function private.update_customer_balance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Si es un pedido a crédito, aumentar saldo
  if tg_op = 'INSERT' and new.sale_type = 'credit' and new.status = 'delivered' then
    update public.customers
    set current_balance = current_balance + new.total
    where id = new.customer_id;
  end if;

  -- Si es un pago a crédito (sin order_id), disminuir saldo
  if tg_op = 'INSERT' and new.order_id is null and new.customer_id is not null then
    update public.customers
    set current_balance = current_balance - new.amount
    where id = new.customer_id;
  end if;

  return new;
end;
$$;

create trigger on_order_delivered
  after update on public.orders
  for each row
  when (old.status != 'delivered' and new.status = 'delivered' and new.sale_type = 'credit')
  execute function private.update_customer_balance();

create trigger on_credit_payment
  after insert on public.payments
  for each row
  when (new.order_id is null and new.customer_id is not null)
  execute function private.update_customer_balance();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - POLÍTICAS DE ACCESO
-- ============================================================================

-- Habilitar RLS en todas las tablas
alter table public.profiles enable row level security;
alter table public.brands enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_lots enable row level security;
alter table public.price_history enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.customers enable row level security;
alter table public.customer_baskets enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_edits enable row level security;
alter table public.order_item_cancellations enable row level security;
alter table public.order_reminders enable row level security;
alter table public.payments enable row level security;
alter table public.suppliers enable row level security;
alter table public.supplier_invoices enable row level security;
alter table public.supplier_invoice_items enable row level security;
alter table public.cash_registers enable row level security;
alter table public.shifts enable row level security;
alter table public.cash_transactions enable row level security;
alter table public.daily_closings enable row level security;
alter table public.weekly_closings enable row level security;
alter table public.expenses enable row level security;
alter table public.promotions enable row level security;
alter table public.coupons enable row level security;
alter table public.loyalty_points enable row level security;
alter table public.scheduled_orders enable row level security;
alter table public.scheduled_order_items enable row level security;
alter table public.messages enable row level security;
alter table public.audit_logs enable row level security;

-- ============================================================================
-- POLÍTICAS RLS: PROFILES
-- ============================================================================

-- Todos los usuarios autenticados pueden ver perfiles
create policy "Profiles are viewable by authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

-- Solo admins pueden modificar perfiles
create policy "Only admins can update profiles"
  on public.profiles for update
  to authenticated
  using (private.is_admin());

-- ============================================================================
-- POLÍTICAS RLS: PRODUCTS, BRANDS, CATEGORIES
-- ============================================================================

-- Todos pueden ver productos, marcas y categorías
create policy "Products are viewable by all"
  on public.products for select to authenticated using (true);

create policy "Brands are viewable by all"
  on public.brands for select to authenticated using (true);

create policy "Categories are viewable by all"
  on public.categories for select to authenticated using (true);

-- Solo sellers y admins pueden crear/modificar productos
create policy "Sellers and admins can manage products"
  on public.products for all to authenticated
  using (private.is_seller_or_admin())
  with check (private.is_seller_or_admin());

create policy "Sellers and admins can manage brands"
  on public.brands for all to authenticated
  using (private.is_seller_or_admin())
  with check (private.is_seller_or_admin());

create policy "Sellers and admins can manage categories"
  on public.categories for all to authenticated
  using (private.is_seller_or_admin())
  with check (private.is_seller_or_admin());

-- ============================================================================
-- POLÍTICAS RLS: ORDERS
-- ============================================================================

-- Todos los usuarios autenticados pueden ver pedidos
create policy "Orders are viewable by authenticated users"
  on public.orders for select to authenticated using (true);

-- Sellers y admins pueden crear pedidos
create policy "Sellers and admins can create orders"
  on public.orders for insert to authenticated
  with check (private.is_seller_or_admin() and seller_id = auth.uid());

-- Sellers pueden actualizar sus propios pedidos, admins todos
create policy "Users can update their own orders"
  on public.orders for update to authenticated
  using (
    (seller_id = auth.uid() and private.is_seller_or_admin())
    or private.is_admin()
    or (delivery_person_id = auth.uid() and status in ('in_transit', 'delivered'))
  );

-- ============================================================================
-- POLÍTICAS RLS: ORDER_EDITS, ORDER_ITEM_CANCELLATIONS, ORDER_REMINDERS
-- ============================================================================

-- Order edits: todos pueden ver, solo sellers/admins pueden crear
create policy "Order edits are viewable by authenticated users"
  on public.order_edits for select to authenticated using (true);

create policy "Sellers and admins can create order edits"
  on public.order_edits for insert to authenticated
  with check (private.is_seller_or_admin());

-- Order item cancellations: todos pueden ver, solo sellers/admins pueden crear
create policy "Order item cancellations are viewable by authenticated users"
  on public.order_item_cancellations for select to authenticated using (true);

create policy "Sellers and admins can create order item cancellations"
  on public.order_item_cancellations for insert to authenticated
  with check (private.is_seller_or_admin());

-- Order reminders: usuarios ven sus propios recordatorios, admins ven todos
create policy "Users can view their own reminders"
  on public.order_reminders for select to authenticated
  using (sent_to = auth.uid() or private.is_admin());

create policy "System can create reminders"
  on public.order_reminders for insert to authenticated
  with check (true);

create policy "Users can acknowledge their own reminders"
  on public.order_reminders for update to authenticated
  using (sent_to = auth.uid());

-- ============================================================================
-- POLÍTICAS RLS: CUSTOMERS
-- ============================================================================

-- Todos pueden ver clientes
create policy "Customers are viewable by authenticated users"
  on public.customers for select to authenticated using (true);

-- Sellers y admins pueden gestionar clientes
create policy "Sellers and admins can manage customers"
  on public.customers for all to authenticated
  using (private.is_seller_or_admin())
  with check (private.is_seller_or_admin());

-- ============================================================================
-- POLÍTICAS RLS: PAYMENTS
-- ============================================================================

-- Todos pueden ver pagos
create policy "Payments are viewable by authenticated users"
  on public.payments for select to authenticated using (true);

-- Sellers y admins pueden crear pagos
create policy "Sellers and admins can create payments"
  on public.payments for insert to authenticated
  with check (private.is_seller_or_admin());

-- ============================================================================
-- POLÍTICAS RLS: INVENTORY
-- ============================================================================

-- Todos pueden ver movimientos de inventario
create policy "Inventory movements are viewable by authenticated users"
  on public.inventory_movements for select to authenticated using (true);

-- Solo sellers y admins pueden crear movimientos
create policy "Sellers and admins can create inventory movements"
  on public.inventory_movements for insert to authenticated
  with check (private.is_seller_or_admin());

-- ============================================================================
-- POLÍTICAS RLS: SUPPLIERS (solo admins)
-- ============================================================================

create policy "Suppliers are viewable by authenticated users"
  on public.suppliers for select to authenticated using (true);

create policy "Only admins can manage suppliers"
  on public.suppliers for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create policy "Only admins can manage supplier invoices"
  on public.supplier_invoices for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- ============================================================================
-- POLÍTICAS RLS: FINANCIAL (solo admins)
-- ============================================================================

create policy "Only admins can view cash registers"
  on public.cash_registers for select to authenticated
  using (private.is_admin());

create policy "Only admins can manage shifts"
  on public.shifts for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create policy "Only admins can view daily closings"
  on public.daily_closings for select to authenticated
  using (private.is_admin());

create policy "Only admins can view weekly closings"
  on public.weekly_closings for select to authenticated
  using (private.is_admin());

-- ============================================================================
-- POLÍTICAS RLS: MESSAGES
-- ============================================================================

-- Usuarios pueden ver mensajes donde son remitente o destinatario
create policy "Users can view their own messages"
  on public.messages for select to authenticated
  using (sender_id = auth.uid() or recipient_id = auth.uid());

-- Usuarios pueden enviar mensajes
create policy "Users can send messages"
  on public.messages for insert to authenticated
  with check (sender_id = auth.uid());

-- ============================================================================
-- POLÍTICAS RLS: AUDIT LOGS (solo admins)
-- ============================================================================

create policy "Only admins can view audit logs"
  on public.audit_logs for select to authenticated
  using (private.is_admin());

-- ============================================================================
-- FUNCIONES: ENTREGAS PARCIALES Y RECORDATORIOS
-- ============================================================================

-- Función para marcar items como entregados y actualizar estado del pedido
create or replace function private.mark_items_delivered(
  p_order_id uuid,
  p_delivered_items jsonb -- array de {order_item_id, quantity_delivered}
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item jsonb;
  v_total_items integer;
  v_delivered_items integer;
  v_all_delivered boolean;
begin
  for v_item in select * from jsonb_array_elements(p_delivered_items)
  loop
    update public.order_items
    set
      quantity_delivered = (v_item->>'quantity_delivered')::numeric,
      delivered_at = now()
    where id = (v_item->>'order_item_id')::uuid
      and order_id = p_order_id;
  end loop;

  select
    count(*),
    count(*) filter (where quantity_delivered >= quantity)
  into v_total_items, v_delivered_items
  from public.order_items
  where order_id = p_order_id;

  v_all_delivered := (v_total_items = v_delivered_items);

  if v_all_delivered then
    update public.orders
    set status = 'delivered', delivered_at = now()
    where id = p_order_id;
  elsif v_delivered_items > 0 then
    update public.orders
    set status = 'partially_delivered'
    where id = p_order_id;
  end if;
end;
$$;

-- Función para obtener pedidos pendientes con tiempo transcurrido
create or replace function private.get_pending_orders_summary()
returns table(
  order_id uuid,
  order_number integer,
  customer_name text,
  created_at timestamptz,
  minutes_pending integer,
  status text,
  pending_items_count bigint,
  priority text
)
language sql
security definer
set search_path = ''
as $$
  select
    o.id as order_id,
    o.order_number,
    c.full_name as customer_name,
    o.created_at,
    extract(epoch from (now() - o.created_at))::integer / 60 as minutes_pending,
    o.status::text,
    count(oi.id) filter (where oi.quantity_delivered < oi.quantity) as pending_items_count,
    case
      when extract(epoch from (now() - o.created_at)) / 60 > 120 then 'urgent'
      when extract(epoch from (now() - o.created_at)) / 60 > 60 then 'high'
      when extract(epoch from (now() - o.created_at)) / 60 > 30 then 'normal'
      else 'low'
    end as priority
  from public.orders o
  left join public.customers c on o.customer_id = c.id
  left join public.order_items oi on o.id = oi.order_id
  where o.status in ('pending', 'preparing', 'ready', 'in_transit', 'partially_delivered')
  group by o.id, o.order_number, c.full_name, o.created_at, o.status
  order by minutes_pending desc;
$$;

-- Función para crear recordatorio automático
create or replace function private.create_order_reminder(
  p_order_id uuid,
  p_reminder_type text,
  p_sent_to uuid,
  p_message text,
  p_priority integer default 1,
  p_metadata jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reminder_id uuid;
begin
  insert into public.order_reminders (
    order_id, reminder_type, sent_to, message, priority, metadata
  ) values (
    p_order_id, p_reminder_type, p_sent_to, p_message, p_priority, p_metadata
  )
  returning id into v_reminder_id;

  return v_reminder_id;
end;
$$;

-- Función para cancelar pedido completo
create or replace function private.cancel_order(
  p_order_id uuid,
  p_reason text,
  p_cancelled_by uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order_status text;
  v_sale_type text;
  v_customer_id uuid;
  v_order_total numeric;
begin
  -- Obtener datos del pedido
  select status, sale_type, customer_id, total
  into v_order_status, v_sale_type, v_customer_id, v_order_total
  from public.orders
  where id = p_order_id;

  -- Validar que el pedido no esté entregado
  if v_order_status = 'delivered' then
    raise exception 'No se puede cancelar un pedido entregado';
  end if;

  -- Restaurar stock de todos los items
  update public.products p
  set stock_current = stock_current + oi.quantity
  from public.order_items oi
  where oi.order_id = p_order_id
    and oi.product_id = p.id;

  -- Registrar movimientos de inventario (devolución)
  insert into public.inventory_movements (product_id, movement_type, quantity, reference_id, reference_type, notes, created_by)
  select
    oi.product_id,
    'return_in',
    oi.quantity,
    p_order_id,
    'order',
    'Cancelación de pedido: ' || p_reason,
    p_cancelled_by
  from public.order_items oi
  where oi.order_id = p_order_id;

  -- Si era a crédito, revertir saldo del cliente
  if v_sale_type = 'credit' and v_customer_id is not null then
    update public.customers
    set current_balance = current_balance - v_order_total
    where id = v_customer_id;
  end if;

  -- Actualizar estado del pedido
  update public.orders
  set
    status = 'cancelled',
    cancelled_reason = p_reason,
    cancelled_by = p_cancelled_by,
    cancelled_at = now()
  where id = p_order_id;
end;
$$;

-- Función para editar item de pedido
create or replace function private.edit_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_new_quantity numeric,
  p_edited_by uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old_quantity numeric;
  v_product_id uuid;
  v_unit_price numeric;
  v_quantity_diff numeric;
  v_order_status text;
  v_new_subtotal numeric;
  v_order_subtotal numeric;
  v_order_total numeric;
begin
  -- Obtener estado del pedido
  select status into v_order_status
  from public.orders
  where id = p_order_id;

  -- Validar que el pedido se pueda editar
  if v_order_status not in ('pending', 'preparing') then
    raise exception 'Solo se pueden editar pedidos en estado pendiente o en preparación';
  end if;

  -- Obtener datos del item
  select quantity, product_id, unit_price
  into v_old_quantity, v_product_id, v_unit_price
  from public.order_items
  where id = p_order_item_id and order_id = p_order_id;

  -- Calcular diferencia
  v_quantity_diff := p_new_quantity - v_old_quantity;

  -- Actualizar item
  v_new_subtotal := p_new_quantity * v_unit_price;
  update public.order_items
  set
    quantity = p_new_quantity,
    subtotal = v_new_subtotal
  where id = p_order_item_id;

  -- Ajustar stock
  if v_quantity_diff > 0 then
    -- Aumentó cantidad, restar stock
    update public.products
    set stock_current = stock_current - v_quantity_diff
    where id = v_product_id;

    insert into public.inventory_movements (product_id, movement_type, quantity, reference_id, reference_type, notes, created_by)
    values (v_product_id, 'sale', v_quantity_diff, p_order_id, 'order', 'Edición de pedido: aumento de cantidad', p_edited_by);
  elsif v_quantity_diff < 0 then
    -- Disminuyó cantidad, devolver stock
    update public.products
    set stock_current = stock_current + abs(v_quantity_diff)
    where id = v_product_id;

    insert into public.inventory_movements (product_id, movement_type, quantity, reference_id, reference_type, notes, created_by)
    values (v_product_id, 'return_in', abs(v_quantity_diff), p_order_id, 'order', 'Edición de pedido: disminución de cantidad', p_edited_by);
  end if;

  -- Recalcular totales del pedido
  select sum(subtotal) into v_order_subtotal
  from public.order_items
  where order_id = p_order_id;

  select subtotal + tax_amount + delivery_fee - discount_amount into v_order_total
  from public.orders
  where id = p_order_id;

  update public.orders
  set
    subtotal = v_order_subtotal,
    total = v_order_subtotal + tax_amount + delivery_fee - discount_amount,
    edit_count = edit_count + 1
  where id = p_order_id;

  -- Registrar edición
  insert into public.order_edits (order_id, edited_by, edit_type, field_changed, old_value, new_value, reason)
  values (
    p_order_id,
    p_edited_by,
    'change_quantity',
    'quantity',
    jsonb_build_object('quantity', v_old_quantity, 'subtotal', v_old_quantity * v_unit_price),
    jsonb_build_object('quantity', p_new_quantity, 'subtotal', v_new_subtotal),
    p_reason
  );
end;
$$;

-- Función para obtener recordatorios pendientes
create or replace function private.get_pending_reminders(
  p_user_id uuid default null
)
returns table(
  reminder_id uuid,
  order_id uuid,
  order_number integer,
  reminder_type text,
  message text,
  priority integer,
  sent_at timestamptz,
  customer_name text
)
language sql
security definer
set search_path = ''
as $$
  select
    r.id as reminder_id,
    r.order_id,
    o.order_number,
    r.reminder_type,
    r.message,
    r.priority,
    r.sent_at,
    c.full_name as customer_name
  from public.order_reminders r
  join public.orders o on r.order_id = o.id
  left join public.customers c on o.customer_id = c.id
  where r.acknowledged = false
    and (p_user_id is null or r.sent_to = p_user_id)
  order by r.priority desc, r.sent_at desc;
$$;

-- Función para crear pedido completo
create or replace function private.create_order_with_items(
  p_customer_id uuid,
  p_seller_id uuid,
  p_sale_type sale_type,
  p_delivery_type delivery_type,
  p_items jsonb, -- array de {product_id, quantity, unit_price, discount_amount}
  p_notes text default null,
  p_delivery_address text default null,
  p_delivery_latitude numeric default null,
  p_delivery_longitude numeric default null,
  p_delivery_fee numeric default 0
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order_id uuid;
  v_order_number integer;
  v_item jsonb;
  v_subtotal numeric := 0;
  v_discount numeric := 0;
  v_total numeric := 0;
  v_product_stock integer;
begin
  -- Obtener siguiente número de pedido
  select coalesce(max(order_number), 0) + 1 into v_order_number from orders;

  -- Crear pedido
  insert into orders (
    order_number, customer_id, seller_id, sale_type, delivery_type,
    subtotal, discount_amount, delivery_fee, total, notes,
    delivery_address, delivery_latitude, delivery_longitude
  )
  values (
    v_order_number, p_customer_id, p_seller_id, p_sale_type, p_delivery_type,
    0, 0, p_delivery_fee, 0, p_notes,
    p_delivery_address, p_delivery_latitude, p_delivery_longitude
  )
  returning id into v_order_id;

  -- Insertar items y calcular totales
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    -- Validar stock
    select stock_current into v_product_stock
    from public.products
    where id = (v_item->>'product_id')::uuid;

    if v_product_stock < (v_item->>'quantity')::numeric then
      raise exception 'Stock insuficiente para el producto %', (v_item->>'product_id')::uuid;
    end if;

    -- Insertar item
    insert into order_items (order_id, product_id, quantity, unit_price, discount_amount, subtotal)
    values (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'quantity')::numeric,
      (v_item->>'unit_price')::numeric,
      coalesce((v_item->>'discount_amount')::numeric, 0),
      ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric) - coalesce((v_item->>'discount_amount')::numeric, 0)
    );

    v_subtotal := v_subtotal + ((v_item->>'quantity')::numeric * (v_item->>'unit_price')::numeric);
    v_discount := v_discount + coalesce((v_item->>'discount_amount')::numeric, 0);

    -- Descontar stock
    update public.products
    set stock_current = stock_current - (v_item->>'quantity')::integer
    where id = (v_item->>'product_id')::uuid;

    -- Registrar movimiento de inventario
    insert into inventory_movements (product_id, movement_type, quantity, reference_id, reference_type, created_by)
    values (
      (v_item->>'product_id')::uuid,
      'sale',
      (v_item->>'quantity')::integer,
      v_order_id,
      'order',
      p_seller_id
    );
  end loop;

  v_total := v_subtotal - v_discount + p_delivery_fee;

  -- Actualizar totales del pedido
  update orders
  set
    subtotal = v_subtotal,
    discount_amount = v_discount,
    total = v_total
  where id = v_order_id;

  return v_order_id;
end;
$$;

-- ============================================================================
-- DATOS INICIALES
-- ============================================================================

-- Insertar caja principal y caja fuerte
insert into public.cash_registers (name, description, is_safe) values
  ('Caja Principal', 'Caja principal del punto de venta', false),
  ('Caja Fuerte', 'Caja fuerte para resguardo de dinero', true);

-- Insertar categorías principales
insert into public.categories (name, slug, description) values
  ('Cerveza', 'cerveza', 'Cervezas nacionales e importadas'),
  ('Aguardiente', 'aguardiente', 'Aguardientes y licores tradicionales'),
  ('Ron', 'ron', 'Rones y destilados de caña'),
  ('Whisky', 'whisky', 'Whiskies y bourbons'),
  ('Tequila', 'tequila', 'Tequilas y mezcales'),
  ('Brandy', 'brandy', 'Brandies y coñacs'),
  ('Crema', 'crema', 'Cremas de licor'),
  ('Vino', 'vino', 'Vinos tintos, blancos y rosados'),
  ('Malta', 'malta', 'Maltas y bebidas sin alcohol'),
  ('Bebida Gaseosa', 'bebida-gaseosa', 'Gaseosas y refrescos'),
  ('Agua', 'agua', 'Aguas naturales y saborizadas'),
  ('Bebida Energética', 'bebida-energetica', 'Energizantes y deportivas'),
  ('Cigarrillos', 'cigarrillos', 'Cigarrillos y tabaco'),
  ('Refajo', 'refajo', 'Refajos y bebidas mezcladas');

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================
-- Este schema incluye:
-- ✓ 31 tablas principales (orders, order_items, order_edits, order_item_cancellations, order_reminders + 26 más)
-- ✓ Tipos enumerados para estados y categorías
-- ✓ Índices optimizados para queries frecuentes
-- ✓ Triggers para actualización automática de timestamps
-- ✓ Triggers para auditoría automática
-- ✓ Triggers para actualización de stock y saldos
-- ✓ Row Level Security (RLS) en todas las tablas
-- ✓ Políticas de acceso por rol (admin, seller, delivery)
-- ✓ Funciones de seguridad en schema privado
-- ✓ Funciones para gestión de pedidos:
--   - mark_items_delivered: marcar items como entregados (entregas parciales)
--   - get_pending_orders_summary: obtener resumen de pedidos pendientes con tiempo transcurrido
--   - create_order_reminder: crear recordatorios automáticos
--   - cancel_order: cancelar pedido completo con reversión de stock y saldos
--   - edit_order_item: editar cantidad de item con ajuste de stock y totales
--   - get_pending_reminders: obtener recordatorios pendientes por usuario
--   - create_order_with_items: crear pedido completo con validación de stock
-- ✓ Datos iniciales (cajas y categorías)
--
-- Próximos pasos:
-- 1. Crear proyecto en Supabase
-- 2. Ejecutar este SQL en el SQL Editor
-- 3. Configurar autenticación (email/password)
-- 4. Crear usuarios de prueba (admin, seller, delivery)
-- 5. Importar productos desde el catálogo Excel
-- 6. Configurar Edge Functions para recordatorios automáticos (cron job)
-- ============================================================================
