-- ============================================================================
-- DATOS INICIALES - LICORERÍA
-- ============================================================================
-- Este script inserta los datos iniciales necesarios para el funcionamiento
-- del sistema: categorías de productos y cajas registradoras.
-- ============================================================================

-- Insertar cajas registradoras
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

-- Verificar inserción
select 'Cajas registradoras: ' || count(*) from public.cash_registers;
select 'Categorías: ' || count(*) from public.categories;
