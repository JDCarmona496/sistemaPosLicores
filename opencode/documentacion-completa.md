# Sistema de Gestión para Licorería - Documentación Completa

## Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Requerimientos Funcionales](#requerimientos-funcionales)
4. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
5. [Base de Datos](#base-de-datos)
6. [Guía de Desarrollo](#guía-de-desarrollo)
7. [Próximos Pasos](#próximos-pasos)

---

## Resumen Ejecutivo

Sistema multiplataforma (iOS, Android, Web, Windows) para la gestión integral de una licorería, con soporte para múltiples roles (Vendedor, Domiciliario, Administrador), impresión térmica Bluetooth, y sincronización en tiempo real.

**Características principales:**
- Multiplataforma: iOS, Android, Web, Windows
- Multi-rol: Vendedor, Domiciliario, Administrador
- Impresión Bluetooth: Soporte para impresoras térmicas ESC/POS
- Offline-first: Funciona sin internet
- Tiempo real: Sincronización en vivo entre dispositivos
- Escaneo de códigos de barras
- Control de inventario completo
- Gestión de clientes con crédito y canastas retornables
- Edición y cancelación de pedidos con auditoría
- Entregas parciales y recordatorios automáticos

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL, Auth, Realtime) |
| State Management | Riverpod |
| Navegación | Go Router |
| BD Local | Drift (SQLite) |
| Impresión | flutter_thermal_printer |
| Escaneo | mobile_scanner |
| Modelos | Freezed + JSON Serializable |

**Costo:** $0 (tier gratuito de Supabase)

---

## Requerimientos Funcionales

### 1. Roles y Permisos

#### 1.1 Vendedor (Punto de Venta)
- Registrar pedidos (contado y crédito)
- Escanear códigos de barras
- Ver precios de productos
- Imprimir y reimprimir facturas
- Registrar devoluciones de canastas
- Ver clientes frecuentes
- Registrar gastos del día
- Realizar cierre de caja diario
- **NO puede:** modificar precios, eliminar pedidos, ver reportes financieros completos

#### 1.2 Domiciliario
- Ver lista de pedidos pendientes (ordenados por prioridad/hora)
- Ver detalles del pedido (dirección, coordenadas GPS, contacto)
- Cambiar estado del pedido (en camino, entregado)
- Tomar foto de entrega como prueba
- Obtener firma digital en entregas a crédito
- Ver historial personal de entregas del día
- **NO puede:** modificar pedidos, ver información financiera

#### 1.3 Administrador (Dueño)
- Todo lo del vendedor +
- Dashboard en tiempo real con métricas
- Gestión completa de inventario
- Gestión de proveedores y facturas
- Cierre semanal con pagos fijos
- Reportes y analytics
- Configuración del sistema
- Logs de auditoría
- Gestión de usuarios y permisos
- Control de caja fuerte
- Ajustes de precios

### 2. Módulo de Productos e Inventario

#### 2.1 Catálogo de Productos
- **Datos:** nombre, código de barras, categoría, unidad de medida, imagen
- **Precios:** precio al detal, precio al por mayor, precio frio (venta suelta de paquete)
- **Inventario:** stock actual, stock mínimo, stock máximo, ubicación en bodega
- **Control de vencimientos:** fecha de vencimiento por lote, alertas
- **Gestión de lotes:** número de lote, fecha de ingreso, proveedor, cantidad
- **Canastas retornables:** productos asociados a canastas con valor de depósito

#### 2.2 Escaneo y Búsqueda
- Escaneo de código de barras con cámara del celular
- Búsqueda por nombre, código, categoría
- Búsqueda rápida con autocompletado
- Historial de productos escaneados recientemente
- Visualización rápida de precio detal y mayorista

#### 2.3 Movimientos de Inventario
- **Entradas:** compras a proveedores, devoluciones de clientes, ajustes positivos
- **Salidas:** ventas, devoluciones a proveedores, mermas, ajustes negativos
- **Transferencias:** entre ubicaciones (futuro multi-sucursal)
- **Ajustes:** inventarios físicos, correcciones
- Cada movimiento registra: usuario, fecha, motivo, cantidad, referencia

#### 2.4 Alertas y Notificaciones
- Stock por debajo del mínimo → notificación al administrador
- Productos próximos a vencer (30, 15, 7 días) → alerta
- Productos sin movimiento en X días → reporte de productos estancados

### 3. Módulo de Pedidos y Ventas

#### 3.1 Registro de Pedidos
- Agregar productos por escaneo o búsqueda
- Selección automática de precio según tipo de cliente (detal/mayorista)
- Venta fraccionada con precio mayorista (ej: media canasta de cerveza)
- Cálculo automático de canastas retornables involucradas
- Selección de tipo de venta: contado o crédito
- Selección de tipo de entrega: en punto de venta o domicilio
- Descuentos manuales con registro de motivo
- Métodos de pago múltiples en un mismo pedido
- Campo de observaciones/notas del pedido
- Carrito persistente (no se pierde si se interrumpe la venta)

#### 3.2 Estados del Pedido
- `pendiente` → recién creado
- `en_preparacion` → se está armando
- `listo` → listo para entrega/despacho
- `en_camino` → domiciliario lo lleva (solo domicilios)
- `entregado` → completado
- `parcialmente_entregado` → algunos productos entregados
- `cancelado` → anulado con motivo
- `devuelto` → devolución parcial o total

#### 3.3 Facturación e Impresión
- Generación automática de número de factura consecutivo
- Impresión en impresora térmica Bluetooth (ESC/POS)
- Diseño de factura personalizable
- Datos en factura: número, fecha, vendedor, cliente, productos, cantidades, precios, subtotal, descuentos, total, método de pago, canastas retornables
- Código QR en factura para verificación/reimpresión
- Reimpresión de facturas anteriores
- Vista previa antes de imprimir
- Opción de enviar factura por WhatsApp (PDF o imagen)

#### 3.4 Cotizaciones
- Crear cotización sin afectar inventario
- Validez configurable (ej: 3 días)
- Convertir cotización en pedido con un clic
- Imprimir cotización
- Enviar por WhatsApp usando `wa.me/+57...`
- Historial de cotizaciones por cliente

#### 3.5 Edición de Pedidos
- **Editar pedido antes de imprimir**: agregar/quitar productos, cambiar cantidades, cambiar cliente
- **Editar pedido en estado `pendiente` o `en_preparacion`**:
  - Agregar productos nuevos
  - Modificar cantidades de productos existentes
  - Eliminar productos del pedido
  - Cambiar tipo de entrega (domicilio ↔ punto de venta)
  - Cambiar método de pago
  - Modificar descuentos aplicados
  - Cambiar observaciones
- **Restricciones de edición**:
  - NO se puede editar pedidos en estado `en_camino`, `entregado` o `cancelado`
  - NO se puede cambiar el tipo de cliente (detal/mayorista) después de crear el pedido
  - Si el pedido ya fue impreso, se debe reimprimir con los cambios
- **Auditoría de edición**:
  - Registrar quién editó, cuándo, y qué cambió (antes/después)
  - Historial completo de ediciones del pedido
  - Notificar al domiciliario si el pedido ya estaba asignado

#### 3.6 Cancelación de Pedidos
- **Cancelar pedido en cualquier estado** (excepto `entregado`)
- **Motivos de cancelación obligatorios** (seleccionar o escribir):
  - Cliente canceló
  - Producto agotado
  - Error en el pedido
  - Cliente no disponible (domicilio)
  - Problema con el pago
  - Otro (especificar)
- **Flujo de cancelación**:
  1. Seleccionar pedido → botón "Cancelar"
  2. Seleccionar/escribir motivo
  3. Confirmar cancelación
  4. Sistema revierte automáticamente:
     - Stock de productos (si ya se había descontado)
     - Saldo del cliente (si era a crédito)
     - Canastas retornables pendientes
     - Asignación al domiciliario
  5. Generar nota de cancelación (imprimible opcional)
  6. Notificar al domiciliario si estaba asignado
- **Cancelación parcial**:
  - Permitir cancelar solo algunos productos del pedido
  - Recalcular totales automáticamente
  - Registrar qué productos se cancelaron y por qué
- **Permisos de cancelación**:
  - Vendedor: puede cancelar sus propios pedidos en estado `pendiente` o `en_preparacion`
  - Admin: puede cancelar cualquier pedido en cualquier estado (excepto `entregado`)
  - Domiciliario: NO puede cancelar, solo reportar problemas
- **Auditoría de cancelación**:
  - Registrar quién canceló, cuándo, motivo completo
  - Pedido cancelado permanece en el sistema (no se elimina) con estado `cancelado`
  - Reportes de cancelaciones: frecuencia, motivos más comunes, por vendedor

#### 3.7 Entregas Parciales y Pendientes
- **Marcar productos como entregados parcialmente**:
  - Cuando el domiciliario entrega solo algunos productos del pedido
  - Ejemplo: entregó la cerveza pero no el licor (licor agotado o no disponible)
  - Registrar qué productos se entregaron y cuáles quedan pendientes
- **Estado del pedido con entrega parcial**: `parcialmente_entregado`
  - Se mantiene en este estado hasta que se entreguen todos los productos o se cancelen los pendientes
- **Flujo de entrega parcial**:
  1. Domiciliario marca productos entregados al completar la entrega
  2. Sistema identifica productos NO entregados
  3. Pedido pasa a estado `parcialmente_entregado`
  4. Se genera recordatorio automático para completar la entrega
  5. Vendedor/admin puede ver lista de pedidos con entregas parciales
- **Completar entrega pendiente**:
  - Desde el pedido, agregar los productos faltantes
  - Marcar como entregados cuando se despachen
  - Pedido pasa a estado `entregado` cuando todos los items están entregados
- **Reportes de entregas parciales**:
  - Lista de pedidos con productos pendientes
  - Tiempo que llevan pendientes
  - Productos más frecuentemente pendientes

#### 3.8 Sistema de Recordatorios de Pedidos
- **Recordatorios automáticos para pedidos pendientes**:
  - **Pedidos sin entregar (>30 min)**: notificación al vendedor y domiciliario
  - **Pedidos sin entregar (>1 hora)**: notificación al admin
  - **Pedidos parcialmente entregados (>2 horas)**: notificación al vendedor y admin
  - **Pedidos parcialmente entregados (>24 horas)**: alerta prioritaria al admin
- **Configuración de tiempos de recordatorio**:
  - Admin puede configurar los umbrales de tiempo
  - Ejemplo: primera alerta a 30 min, segunda a 1 hora, crítica a 2 horas
- **Tipos de recordatorios**:
  - **Push notification** en la app del vendedor/domiciliario/admin
  - **Badge/contador** en la pantalla de pedidos pendientes
  - **Lista priorizada** de pedidos por tiempo de espera
  - **Color coding**: verde (<30 min), amarillo (30-60 min), rojo (>60 min)
- **Panel de recordatorios**:
  - Vista dedicada con todos los pedidos pendientes ordenados por antigüedad
  - Filtros: por vendedor, por domiciliario, por estado, por tiempo
  - Acción rápida: ver detalle del pedido, contactar al cliente, marcar como entregado
- **Recordatorios de pedidos parcialmente entregados**:
  - Notificación diaria de pedidos con entregas parciales
  - Resumen: "Tienes 3 pedidos con productos pendientes de entrega"
  - Detalle: qué productos faltan, desde cuándo, cliente
- **Escalamiento automático**:
  - Si un pedido lleva >2 horas sin entregarse, notificar al admin
  - Si un pedido parcialmente entregado lleva >24 horas, marcar como urgente
  - Admin puede reasignar el pedido a otro domiciliario
- **Historial de recordatorios**:
  - Registrar cuándo se enviaron recordatorios
  - Tracking de tiempos de respuesta
  - Métricas: tiempo promedio de entrega, pedidos con más recordatorios

### 4. Módulo de Clientes

#### 4.1 Registro de Clientes
- Datos básicos: nombre, cédula/NIT, teléfono, email
- Dirección con coordenadas GPS (lat/lng) para navegación del domiciliario
- Tipo de cliente: ocasional, frecuente, mayorista, crédito, consignatario
- Precio asignado: detal o mayorista
- Límite de crédito configurable
- Historial completo de compras y pagos
- Saldo actual (para clientes a crédito)

#### 4.2 Clientes a Crédito
- Límite de crédito máximo configurable
- Registro de facturas a crédito con:
  - Fecha de venta
  - Monto total
  - Fecha límite de pago
  - Mensaje personalizado (acuerdos, condiciones)
- Abonos parciales o totales con registro de:
  - Fecha, monto, método de pago, quién recibe
  - Saldo restante actualizado automáticamente
- Aging de cuentas por cobrar:
  - Deudas vigentes, vencidas (30, 60, 90+ días)
  - Reporte de clientes morosos
- Recordatorios de cobro (notificación o mensaje WhatsApp)

#### 4.3 Control de Canastas Retornables
- Registro de canastas por tipo (330cc, 1L, etc.) con valor de depósito
- Al hacer una venta: canastas que salen = obligación de retorno o cobro
- Opciones al entregar:
  - Devuelve todas → sin cargo
  - Devuelve parcial → cobra diferencia o queda en depósito
  - No devuelve → cobra valor de canasta o queda en saldo (solo crédito)
- Estado de canastas por cliente:
  - Canastas en posesión del cliente
  - Depósito en efectivo retenido
  - Canastas pendientes por devolver
- Al devolver canastas posteriormente:
  - Si pagó → se reembolsa el valor
  - Si quedó en saldo → se descuenta de la deuda
  - Si dejó depósito → se devuelve el dinero

#### 4.4 Cliente Consignatario (Caso Especial)
- Inventario separado asignado al cliente
- Registro de mercancía entregada (entrada al inventario del cliente)
- Registro de ventas realizadas por el cliente (salida de su inventario)
- Registro de devoluciones (entrada al inventario principal)
- Liquidación semanal:
  - Mercancía entregada vs vendida vs devuelta
  - Dinero esperado vs dinero recibido
  - Diferencia a favor o en contra
- Reporte de estado del inventario en consignación
- Alertas de inventario sin movimiento o discrepancies

### 5. Módulo de Domicilios y Logística

#### 5.1 Gestión de Domicilios
- Zonas de entrega con costo y tiempo estimado
- Costo de domicilio configurable (por zona, por monto mínimo de compra, gratis si supera X)
- Asignación de domiciliario (manual o automática por orden de llegada)

#### 5.2 Vista del Domiciliario
- Lista de pedidos asignados ordenados por:
  - Prioridad (hora de pedido, urgencia)
  - Cantidad de productos
  - Tipo de pago (contado/credito)
  - Zona de entrega
- Detalle del pedido:
  - Dirección + botón de navegación (Google Maps / Waze)
  - Teléfono del cliente + botón de llamada
  - Productos y cantidades
  - Monto a cobrar
  - Canastas a recoger
  - Notas especiales
- Acciones:
  - Marcar "en camino"
  - Marcar "entregado" con foto de prueba
  - Firma digital para entregas a crédito
  - Registrar pago recibido y método
  - Reportar incidencia (cliente no está, dirección incorrecta, etc.)

#### 5.3 Tracking en Tiempo Real
- El vendedor ve el estado de todos los domicilios
- El administrador ve mapa con domiciliarios activos
- Notificación al vendedor cuando un domicilio se entrega

### 6. Módulo de Proveedores

#### 6.1 Registro de Proveedores
- Datos: nombre, NIT, contacto, teléfono, email, dirección, productos que suministra
- Condiciones de pago: contado, crédito (días de plazo)
- Historial de compras y pagos

#### 6.2 Facturas de Proveedores
- Registro de facturas de compra:
  - Número de factura, fecha, proveedor
  - Productos, cantidad, costo unitario, total
  - Tipo: contado o crédito
  - Fecha de vencimiento (para crédito)
- Actualización automática de inventario al registrar compra
- Actualización de costo de productos (y sugerencia de ajuste de precio de venta)

#### 6.3 Pagos a Proveedores
- Registro de pagos parciales o totales
- Origen del dinero: caja del día, caja fuerte, cuenta bancaria
- Historial de pagos por proveedor
- Saldo pendiente por proveedor
- Alertas de facturas próximas a vencer

### 7. Módulo Financiero y de Caja

#### 7.1 Control de Caja
- Apertura de caja al inicio del día/turno con monto inicial
- Registro de todos los movimientos del día:
  - Ingresos: ventas contado, abonos de crédito, depósitos de canastas
  - Egresos: gastos, pagos a proveedores, devoluciones de dinero
- Cada movimiento registra: monto, concepto, usuario, hora, método de pago

#### 7.2 Cierre Diario
- Conteo de dinero por denominación:
  - Billetes (por denominación: $2.000, $5.000, $10.000, $20.000, $50.000, $100.000)
  - Monedas (por denominación)
  - Nequi (total)
  - Cuentas de ahorro/bancarias (total por cuenta)
- Cálculo automático:
  - Total esperado (según ventas)
  - Total contado (según conteo)
  - Diferencia (sobrante/faltante)
- Pagos de facturas de proveedores con dinero del día
- Opción de "préstamo" entre días:
  - Si no alcanza el dinero del día para pagar una factura, se toma de otro día (caja fuerte)
  - Registro del movimiento con referencia al día origen
- Destino del dinero al cerrar:
  - Todo a caja fuerte
  - Parcial a banco (con registro de consignación)

#### 7.3 Caja Fuerte
- Saldo acumulado de cierres diarios
- Registro de entradas (dinero de cierres, consignaciones)
- Registro de salidas (pagos de facturas, gastos extraordinarios)
- Saldo actual en tiempo real
- Historial de movimientos

#### 7.4 Cierre Semanal
- Resumen de toda la semana:
  - Total ventas (desglosado por día, tipo de pago, vendedor)
  - Total gastos
  - Total pagos a proveedores
  - Total abonos recibidos de créditos
  - Total nequi y cuentas de ahorro
- Pagos fijos semanales configurables:
  - Nóminas (por empleado)
  - Alquiler
  - Servicios (luz, agua, internet)
  - Seguros
  - Otros personalizables
- Pagos variables que se agregan al cierre
- Rectificación de caja fuerte (conteo físico vs saldo en sistema)
- Reporte de facturas pagadas a proveedores en la semana
- Reporte de abonos realizados a deudas activas
- Balance final: ingresos - egresos = utilidad de la semana

#### 7.5 Gastos Diarios
- Registro de gastos con:
  - Concepto/descripción
  - Monto
  - Categoría (servicios, mantenimiento, varios, etc.)
  - Usuario que lo realiza
  - Fecha y hora
  - Origen del dinero (caja, caja fuerte)
- Soporte fotográfico (foto del recibo)

#### 7.6 Reembolsos y Notas Crédito
- Emisión de notas crédito con justa causa
- Motivo obligatorio
- Aprobación del administrador para montos mayores a X
- Registro en el histórico y ajuste de inventario si aplica

### 8. Módulo de Reportes y Analytics

#### 8.1 Dashboard en Tiempo Real (Administrador)
- Ventas del día en curso (total, cantidad de pedidos)
- Pedidos pendientes / en proceso
- Alertas activas (stock bajo, vencimientos, deudas vencidas)
- Top productos vendidos hoy
- Ventas por vendedor
- Domicilios activos

#### 8.2 Reportes de Ventas
- **Diario:** desglose por hora, vendedor, tipo de pago, categoría de producto
- **Semanal/Mensual:** tendencias, comparativas con período anterior
- **Por producto:** más vendidos, menos vendidos, rentabilidad por producto
- **Por cliente:** mejores clientes, frecuencia de compra, ticket promedio
- **Por categoría:** distribución de ventas por tipo de producto
- **Horas pico:** gráfico de ventas por hora del día / día de la semana

#### 8.3 Reportes Financieros
- Estado de resultados simplificado (ingresos - costos - gastos)
- Flujo de caja (entradas y salidas)
- Cuentas por cobrar (clientes) con aging
- Cuentas por pagar (proveedores) con vencimientos
- Rentabilidad bruta por producto y general

#### 8.4 Reportes de Inventario
- Valorización del inventario (a costo y a precio de venta)
- Rotación de productos
- Productos vencidos o próximos a vencer
- Productos sin movimiento (estancados)
- Historial de mermas y ajustes

#### 8.5 Exportación
- Exportar reportes a Excel/CSV
- Exportar a PDF
- Envío programado de reportes por email (al administrador)

### 9. Sistema de Seguridad y Auditoría

#### 9.1 Autenticación
- Login con email y contraseña
- Sesiones persistentes (no se cierra sesión en cada uso)
- PIN rápido para acceso veloz en punto de venta
- Bloqueo automático por inactividad (configurable)

#### 9.2 Logs de Auditoría
- Registro de TODAS las acciones importantes:
  - Creación/modificación/eliminación de pedidos
  - Cambios de precios
  - Ajustes de inventario
  - Apertura/cierre de caja
  - Pagos y abonos
  - Login/logout
  - Impresiones de facturas
- Cada log: usuario, acción, fecha/hora, datos antes/después

#### 9.3 Permisos Granulares
- Cada acción del sistema tiene un permiso asociado
- Configuración por rol y por usuario individual
- Acciones sensibles requieren re-autenticación (ej: eliminar pedido, ajustar precio)

### 10. Configuración y Personalización

#### 10.1 Datos del Negocio
- Nombre, NIT, dirección, teléfono, logo
- Mensaje personalizado en facturas
- Horarios de atención

#### 10.2 Configuración de Factura
- Ancho de papel (58mm, 80mm)
- Elementos visibles/ocultos
- Tamaño de fuente
- Logo y pie de página
- Vista previa en tiempo real

#### 10.3 Configuración General
- Moneda (COP por defecto)
- IVA configurable (incluido/excluido, porcentaje)
- Zonas de entrega y costos de domicilio
- Categorías de productos
- Métodos de pago activos
- Motivos de gasto predefinidos
- Límites de crédito por defecto

#### 10.4 Configuración de Notificaciones
- Alertas de stock mínimo (activar/desactivar)
- Alertas de vencimientos (días de anticipación)
- Notificaciones de nuevos pedidos al domiciliario
- Resumen diario al administrador

### 11. Arquitectura Offline-First

#### 11.1 Funcionamiento Sin Internet
- La app funciona completamente offline para operaciones críticas:
  - Crear pedidos y facturas
  - Escanear productos
  - Imprimir facturas
  - Registrar clientes
- Base de datos local con Drift (SQLite) sincroniza cuando hay conexión

#### 11.2 Sincronización
- Cola de operaciones pendientes cuando no hay internet
- Sincronización automática al recuperar conexión
- Resolución de conflictos (última escritura gana, con log)
- Indicador visual de estado de conexión

### 12. Notificaciones Push

#### 12.1 Para el Domiciliario
- Nuevo pedido asignado
- Cambio en un pedido existente
- Mensaje del administrador

#### 12.2 Para el Administrador
- Alerta de stock mínimo
- Producto próximo a vencer
- Cierre de caja completado
- Venta grande registrada
- Deuda de cliente vencida

#### 12.3 Para el Vendedor
- Recordatorio de cierre de caja
- Pedido de domicilio entregado

### 13. Integraciones

#### 13.1 WhatsApp
- Envío de cotizaciones por `wa.me/+57...`
- Envío de facturas en PDF
- Envío de estados de cuenta a clientes
- Recordatorios de pago

#### 13.2 Mapas
- Navegación a dirección del cliente (Google Maps / Waze)
- Visualización de zonas de entrega
- Geolocalización del domiciliario (futuro)

#### 13.3 Impresora Térmica Bluetooth
- Protocolo ESC/POS
- Soporte para 58mm y 80mm
- Impresión de texto, tablas, códigos de barras, QR, logos
- Estado de conexión de impresora
- Reconexión automática

### 14. Módulos Futuros (Nice-to-Have)

- [ ] Multi-sucursal con transferencias entre sedes
- [ ] App de cliente para hacer pedidos
- [ ] Integración con pasarelas de pago (PayU, Wompi)
- [ ] Facturación electrónica DIAN
- [ ] Integración con Rappi/Didi Food
- [ ] Predicción de demanda con IA
- [ ] Gestión de empleados (turnos, asistencia)
- [ ] Sistema de comisiones por ventas para vendedores

### Resumen de Módulos

| # | Módulo | Prioridad |
|---|--------|-----------|
| 1 | Roles y Permisos | Alta |
| 2 | Productos e Inventario | Alta |
| 3 | Pedidos y Ventas | Alta |
| 4 | Clientes | Alta |
| 5 | Domicilios y Logística | Alta |
| 6 | Proveedores | Media |
| 7 | Financiero y Caja | Alta |
| 8 | Reportes y Analytics | Media |
| 9 | Seguridad y Auditoría | Alta |
| 10 | Configuración | Media |
| 11 | Offline-First | Alta |
| 12 | Notificaciones Push | Media |
| 13 | Integraciones | Alta |
| 14 | Gestión de Turnos y Comisiones | Alta |
| 15 | Pedidos Programados | Media |
| 16 | Dashboard con KPIs | Alta |
| 17 | Mensajería Interna | Media |
| 18 | Reportes Avanzados | Media |
| 19 | API Pública (Contable) | Baja |
| 20 | Catálogo en Redes Sociales | Baja |
| 21 | Módulos Futuros | Baja |

---

## Arquitectura del Proyecto

### Estructura de Carpetas

```
lib/
├── config/              # Configuración global de la app
│   ├── app_config.dart      # Constantes y configuración general
│   ├── supabase_config.dart # Inicialización de Supabase
│   ├── router.dart          # Rutas con go_router
│   └── theme.dart           # Tema de la aplicación
│
├── data/                # Capa de datos
│   ├── models/              # Modelos de API/BD (DTOs)
│   ├── repositories/        # Implementación de repositorios
│   └── services/            # Servicios (API clients, BD local, plugins)
│
├── domain/              # Capa de dominio
│   ├── models/              # Modelos de dominio limpios
│   └── use_cases/           # Lógica de negocio reutilizable (opcional)
│
└── ui/                  # Capa de presentación
    ├── core/                # Componentes compartidos
    │   ├── widgets/             # Widgets reutilizables
    │   ├── constants/           # Constantes de UI
    │   └── utils/               # Utilidades de UI
    └── features/            # Features organizadas por módulo
        ├── auth/                # Autenticación
        ├── dashboard/           # Dashboard principal
        ├── orders/              # Pedidos y ventas
        ├── products/            # Productos e inventario
        ├── customers/           # Clientes
        ├── delivery/            # Domicilios
        ├── reports/             # Reportes y analytics
        └── settings/            # Configuración

assets/
├── images/              # Imágenes de la app
├── icons/               # Iconos personalizados
└── fonts/               # Fuentes personalizadas
```

### Features Implementadas

#### ✅ Configuración Base
- [x] Supabase integrado
- [x] Riverpod para state management
- [x] Go Router para navegación
- [x] Tema claro/oscuro
- [x] Estructura de carpetas

#### 🚧 En Desarrollo
- [ ] Autenticación (login/logout)
- [ ] Dashboard con KPIs
- [ ] Gestión de pedidos
- [ ] Catálogo de productos
- [ ] Gestión de clientes
- [ ] Módulo de domicilios
- [ ] Reportes
- [ ] Configuración

### Dependencias Principales

| Paquete | Uso |
|---------|-----|
| `flutter_riverpod` | State management |
| `supabase_flutter` | Backend (auth, BD, realtime) |
| `drift` | Base de datos local (offline) |
| `go_router` | Navegación |
| `flutter_thermal_printer` | Impresión Bluetooth |
| `mobile_scanner` | Escaneo de códigos de barras |
| `freezed` | Modelos inmutables |
| `geolocator` | GPS para domiciliarios |
| `flutter_local_notifications` | Notificaciones push |

### Flujo de Trabajo para Nuevas Features

1. **Definir modelo de dominio** en `lib/domain/models/`
2. **Crear servicio** en `lib/data/services/` (si necesita API)
3. **Implementar repositorio** en `lib/data/repositories/`
4. **Crear ViewModel** en `lib/ui/features/[feature]/view_models/`
5. **Implementar Vista** en `lib/ui/features/[feature]/views/`
6. **Registrar en router** si es una nueva pantalla
7. **Ejecutar build_runner** si usaste freezed/json_serializable

### Convenciones de Código

- **Nombres de archivos**: `snake_case.dart`
- **Nombres de clases**: `PascalCase`
- **Nombres de variables**: `camelCase`
- **Modelos de dominio**: Usar `@freezed` para inmutabilidad
- **ViewModels**: Extender `ChangeNotifier` o usar `@riverpod`
- **Vistas**: Widgets stateless que escuchan ViewModels

### Estructura de un Feature Completo

```
lib/ui/features/orders/
├── views/
│   ├── orders_view.dart           # Lista de pedidos
│   ├── order_detail_view.dart     # Detalle de pedido
│   └── create_order_view.dart     # Crear nuevo pedido
└── view_models/
    ├── orders_view_model.dart     # Estado de lista
    └── order_detail_view_model.dart # Estado de detalle
```

---

## Base de Datos

### Configuración Inicial en Supabase

#### 1. Crear Proyecto
1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto (anota la contraseña de la base de datos)
3. Espera a que el proyecto esté listo (~2 minutos)

#### 2. Ejecutar el Schema
1. En el dashboard de Supabase, ve a **SQL Editor**
2. Copia todo el contenido de `licoreria-database-schema.sql`
3. Pégalo en el editor y haz clic en **Run**
4. Verifica que no haya errores

#### 3. Configurar Autenticación
1. Ve a **Authentication** > **Providers**
2. Habilita **Email** (desactiva "Confirm email" para desarrollo)
3. Opcional: habilita Google, Facebook, etc.

#### 4. Crear Usuarios de Prueba

```sql
-- Crear usuario admin
insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
values (
  gen_random_uuid(),
  'admin@licoreria.com',
  crypt('admin123', gen_salt('bf')),
  now(),
  '{"full_name": "Administrador", "role": "admin"}'::jsonb
);

-- Crear usuario vendedor
insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
values (
  gen_random_uuid(),
  'vendedor@licoreria.com',
  crypt('vendedor123', gen_salt('bf')),
  now(),
  '{"full_name": "Juan Vendedor", "role": "seller"}'::jsonb
);

-- Crear usuario domiciliario
insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
values (
  gen_random_uuid(),
  'domiciliario@licoreria.com',
  crypt('domiciliario123', gen_salt('bf')),
  now(),
  '{"full_name": "Pedro Domiciliario", "role": "delivery"}'::jsonb
);
```

#### 5. Importar Productos desde Excel

```sql
-- Ejemplo: Insertar productos del catálogo
insert into public.brands (name, slug) values
  ('Poker', 'poker'),
  ('Águila', 'aguila'),
  ('Club Colombia', 'club-colombia')
on conflict (slug) do nothing;

-- Insertar productos (ejemplo con Poker)
insert into public.products (
  code, brand_id, category_id, name, presentation,
  packaging_type, units_per_package, is_cold, is_returnable,
  price_retail, price_wholesale, stock_current, stock_min
)
select
  1000,
  (select id from brands where slug = 'poker'),
  (select id from categories where slug = 'cerveza'),
  'Cerveza Poker',
  '330ml',
  'unit',
  1,
  false,
  false,
  3000.00,
  3000.00,
  50,
  10
on conflict (code) do nothing;
```

### Queries Comunes

#### 1. Obtener Productos con Stock Bajo
```sql
select
  p.code,
  b.name as brand,
  p.name,
  p.presentation,
  p.stock_current,
  p.stock_min
from products p
join brands b on p.brand_id = b.id
where p.stock_current <= p.stock_min
  and p.status = 'active'
order by p.stock_current asc;
```

#### 2. Ventas del Día por Vendedor
```sql
select
  pr.full_name as vendedor,
  count(o.id) as total_pedidos,
  sum(o.total) as total_ventas,
  sum(case when o.sale_type = 'cash' then o.total else 0 end) as ventas_contado,
  sum(case when o.sale_type = 'credit' then o.total else 0 end) as ventas_credito
from orders o
join profiles pr on o.seller_id = pr.id
where date(o.created_at) = current_date
  and o.status = 'delivered'
group by pr.id, pr.full_name
order by total_ventas desc;
```

#### 3. Clientes con Deudas Vencidas
```sql
select
  c.full_name,
  c.phone,
  c.current_balance as saldo,
  count(p.id) as facturas_pendientes,
  min(p.created_at) as factura_mas_antigua,
  current_date - min(p.created_at)::date as dias_vencido
from customers c
join payments p on c.id = p.customer_id
where c.current_balance > 0
  and p.status = 'pending'
group by c.id, c.full_name, c.phone, c.current_balance
having current_date - min(p.created_at)::date > 30
order by dias_vencido desc;
```

#### 4. Productos Más Vendidos (Últimos 30 días)
```sql
select
  p.code,
  p.name,
  b.name as brand,
  sum(oi.quantity) as unidades_vendidas,
  sum(oi.subtotal) as total_ventas,
  count(distinct o.id) as veces_pedido
from order_items oi
join products p on oi.product_id = p.id
join brands b on p.brand_id = b.id
join orders o on oi.order_id = o.id
where o.created_at >= current_date - interval '30 days'
  and o.status = 'delivered'
group by p.id, p.code, p.name, b.name
order by total_ventas desc
limit 20;
```

#### 5. Cierre de Caja Diario
```sql
with ventas_dia as (
  select
    sum(case when pm.payment_method = 'cash' then pm.amount else 0 end) as total_efectivo,
    sum(case when pm.payment_method = 'nequi' then pm.amount else 0 end) as total_nequi,
    sum(case when pm.payment_method = 'transfer' then pm.amount else 0 end) as total_transferencia,
    sum(pm.amount) as total_ventas
  from payments pm
  join orders o on pm.order_id = o.id
  where date(pm.created_at) = current_date
    and pm.status = 'completed'
),
gastos_dia as (
  select sum(amount) as total_gastos
  from expenses
  where date(created_at) = current_date
)
select
  v.total_efectivo,
  v.total_nequi,
  v.total_transferencia,
  v.total_ventas,
  g.total_gastos,
  v.total_ventas - g.total_gastos as neto
from ventas_dia v, gastos_dia g;
```

#### 6. Control de Canastas Retornables por Cliente
```sql
select
  c.full_name as cliente,
  p.name as producto,
  cb.quantity_out - cb.quantity_returned as canastas_pendientes,
  cb.deposit_amount as deposito_retenido,
  cb.status,
  cb.created_at as fecha_salida
from customer_baskets cb
join customers c on cb.customer_id = c.id
join products p on cb.product_id = p.id
where cb.status = 'outstanding'
order by c.full_name, cb.created_at;
```

#### 7. Pedidos Pendientes para Domiciliario
```sql
select
  o.order_number,
  c.full_name as cliente,
  c.phone as telefono,
  o.delivery_address,
  o.total,
  o.sale_type,
  o.created_at,
  count(oi.id) as items
from orders o
left join customers c on o.customer_id = c.id
left join order_items oi on o.id = oi.order_id
where o.status in ('ready', 'in_transit')
  and o.delivery_type = 'delivery'
  and (o.delivery_person_id is null or o.delivery_person_id = auth.uid())
group by o.id, c.full_name, c.phone
order by o.created_at asc;
```

#### 8. Facturas de Proveedores Próximas a Vencer
```sql
select
  s.name as proveedor,
  si.invoice_number,
  si.total,
  si.paid_amount,
  si.total - si.paid_amount as saldo,
  si.due_date,
  si.due_date - current_date as dias_para_vencer
from supplier_invoices si
join suppliers s on si.supplier_id = s.id
where si.status in ('pending', 'partial')
  and si.due_date <= current_date + interval '7 days'
order by si.due_date asc;
```

#### 9. Productos Próximos a Vencer
```sql
select
  p.code,
  p.name,
  pl.lot_number,
  pl.quantity_remaining,
  pl.expiration_date,
  pl.expiration_date - current_date as dias_para_vencer
from product_lots pl
join products p on pl.product_id = p.id
where pl.quantity_remaining > 0
  and pl.expiration_date is not null
  and pl.expiration_date <= current_date + interval '30 days'
order by pl.expiration_date asc;
```

#### 10. Reporte de Auditoría (Acciones de Usuario)
```sql
select
  al.created_at,
  pr.full_name as usuario,
  pr.role,
  al.action,
  al.table_name,
  al.record_id
from audit_logs al
join profiles pr on al.user_id = pr.id
where al.created_at >= current_date - interval '7 days'
order by al.created_at desc
limit 100;
```

### Funciones Útiles

#### Crear Pedido Completo (con transacción)
```sql
-- Función para crear un pedido completo con items, validación de stock y movimientos de inventario
select private.create_order_with_items(
  'customer-uuid-here',           -- p_customer_id
  'seller-uuid-here',             -- p_seller_id
  'cash',                         -- p_sale_type ('cash' o 'credit')
  'in_store',                     -- p_delivery_type ('in_store' o 'delivery')
  '[                              -- p_items (array JSON)
    {"product_id": "uuid-1", "quantity": 2, "unit_price": 3000, "discount_amount": 0},
    {"product_id": "uuid-2", "quantity": 1, "unit_price": 6500, "discount_amount": 500}
  ]'::jsonb,
  'Notas del pedido',             -- p_notes (opcional)
  'Calle 123 #45-67',             -- p_delivery_address (opcional, solo si delivery)
  4.6097,                         -- p_delivery_latitude (opcional)
  -74.0817,                       -- p_delivery_longitude (opcional)
  5000                            -- p_delivery_fee (opcional, default 0)
);
-- Retorna: UUID del pedido creado
```

#### Cancelar Pedido Completo
```sql
-- Función para cancelar un pedido completo con reversión automática de stock y saldos
select private.cancel_order(
  'order-uuid-here',              -- p_order_id
  'Cliente canceló el pedido',    -- p_reason (motivo de cancelación)
  'user-uuid-here'                -- p_cancelled_by (usuario que cancela)
);
-- Efectos:
-- - Restaura stock de todos los productos
-- - Revierte saldo del cliente si era a crédito
-- - Registra movimientos de inventario (devolución)
-- - Actualiza estado del pedido a 'cancelled'
```

#### Editar Item de Pedido
```sql
-- Función para editar la cantidad de un item en un pedido
select private.edit_order_item(
  'order-uuid-here',              -- p_order_id
  'order-item-uuid-here',         -- p_order_item_id
  5,                              -- p_new_quantity (nueva cantidad)
  'user-uuid-here',               -- p_edited_by (usuario que edita)
  'Cliente pidió más unidades'    -- p_reason (opcional, motivo de edición)
);
-- Efectos:
-- - Ajusta stock automáticamente (suma o resta según diferencia)
-- - Recalcula subtotal del item y totales del pedido
-- - Registra movimiento de inventario
-- - Registra edición en order_edits con valores antes/después
-- - Incrementa contador edit_count del pedido
-- Nota: Solo funciona en pedidos con estado 'pending' o 'preparing'
```

#### Marcar Items como Entregados (Entregas Parciales)
```sql
-- Función para marcar items como entregados (soporta entregas parciales)
select private.mark_items_delivered(
  'order-uuid-here',              -- p_order_id
  '[                              -- p_delivered_items (array JSON)
    {"order_item_id": "item-uuid-1", "quantity_delivered": 2},
    {"order_item_id": "item-uuid-2", "quantity_delivered": 1}
  ]'::jsonb
);
-- Efectos:
-- - Actualiza quantity_delivered y delivered_at en cada item
-- - Si todos los items están entregados: estado = 'delivered'
-- - Si solo algunos items: estado = 'partially_delivered'
```

#### Obtener Resumen de Pedidos Pendientes
```sql
-- Función para obtener todos los pedidos pendientes con tiempo transcurrido y prioridad
select * from private.get_pending_orders_summary();
-- Retorna:
-- - order_id, order_number, customer_name
-- - created_at, minutes_pending
-- - status, pending_items_count
-- - priority ('low', 'normal', 'high', 'urgent')
-- Útil para: panel de recordatorios, dashboard de administrador
```

#### Obtener Recordatorios Pendientes
```sql
-- Función para obtener recordatorios pendientes de un usuario específico
select * from private.get_pending_reminders('user-uuid-here');
-- O para obtener todos los recordatorios pendientes (admin)
select * from private.get_pending_reminders(null);
-- Retorna:
-- - reminder_id, order_id, order_number
-- - reminder_type, message, priority
-- - sent_at, customer_name
-- Útil para: notificaciones push, panel de recordatorios
```

#### Crear Recordatorio Automático
```sql
-- Función para crear un recordatorio manual (normalmente se usa desde Edge Functions)
select private.create_order_reminder(
  'order-uuid-here',              -- p_order_id
  'delayed',                      -- p_reminder_type ('delayed', 'partial_delivery', 'urgent', 'daily_summary')
  'user-uuid-here',               -- p_sent_to (usuario que recibe el recordatorio)
  'El pedido #123 lleva más de 1 hora pendiente',  -- p_message
  2,                              -- p_priority (1=normal, 2=alta, 3=urgente)
  '{"minutes_pending": 75}'::jsonb  -- p_metadata (datos adicionales, opcional)
);
-- Retorna: UUID del recordatorio creado
```

#### Registrar Abono a Cliente
```sql
create or replace function register_credit_payment(
  p_customer_id uuid,
  p_amount numeric,
  p_payment_method payment_method,
  p_received_by uuid,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_payment_id uuid;
begin
  -- Crear pago
  insert into payments (customer_id, payment_method, amount, received_by, notes)
  values (p_customer_id, p_payment_method, p_amount, p_received_by, p_notes)
  returning id into v_payment_id;

  -- El trigger update_customer_balance actualizará el saldo automáticamente

  -- Registrar en caja
  insert into cash_transactions (
    shift_id, cash_register_id, transaction_type, amount,
    payment_method, reference_id, reference_type, description, created_by
  )
  select
    (select id from shifts where status = 'open' limit 1),
    (select id from cash_registers where is_safe = false limit 1),
    'income',
    p_amount,
    p_payment_method,
    v_payment_id,
    'credit_payment',
    'Abono de cliente a crédito',
    p_received_by;

  return v_payment_id;
end;
$$;
```

---

## Guía de Desarrollo

### Instalación

#### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd applicoresestacion
```

#### 2. Configurar Supabase

Crear archivo `.env` o configurar variables de entorno:
```bash
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_anon_key
```

O editar directamente en `lib/config/app_config.dart`:
```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'tu_anon_key';
```

#### 3. Instalar dependencias

```bash
flutter pub get
```

#### 4. Generar código (Freezed, JSON Serializable)

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 5. Ejecutar la aplicación

```bash
# Modo debug
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Android
flutter run -d android
```

### Comandos Útiles

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Analizar código
flutter analyze

# Formatear código
dart format lib/

# Ejecutar tests
flutter test

# Build para producción
flutter build apk --release
flutter build ios --release
flutter build web --release
flutter build windows --release

# Ver logs en tiempo real
flutter logs
```

### Testing

```bash
# Unit tests
flutter test test/

# Tests específicos
flutter test test/domain/models/
flutter test test/data/repositories/
```

### Notas Importantes

1. **Offline-first**: La app debe funcionar sin internet usando Drift (SQLite local)
2. **Sincronización**: Cuando hay conexión, sincronizar con Supabase
3. **Roles**: La UI debe adaptarse según el rol del usuario (admin, seller, delivery)
4. **Impresión**: Usar `flutter_thermal_printer` para impresoras Bluetooth ESC/POS
5. **Códigos de barras**: `mobile_scanner` para escaneo, generar EAN si no existen

---

## Próximos Pasos

### Inmediatos

1. **Configurar credenciales de Supabase** en `lib/config/app_config.dart`
2. **Implementar login funcional** con autenticación de Supabase
3. **Implementar pantalla de pedidos** con CRUD completo
4. **Implementar escaneo de códigos de barras** con mobile_scanner

### Corto Plazo

5. **Implementar catálogo de productos** con búsqueda y filtros
6. **Implementar gestión de clientes** con tipos y crédito
7. **Implementar módulo de domicilios** con asignación y tracking
8. **Configurar impresión Bluetooth** con flutter_thermal_printer

### Mediano Plazo

9. **Implementar reportes y dashboard** con gráficos
10. **Implementar sistema de recordatorios** automáticos
11. **Implementar entregas parciales** y cancelaciones
12. **Configurar notificaciones push** locales

### Largo Plazo

13. **Implementar sincronización offline** con Drift
14. **Implementar auditoría completa** de acciones
15. **Implementar gestión de proveedores** y facturas
16. **Implementar cierre de caja** diario y semanal

---

## Recursos

- [Documentación de Supabase](https://supabase.com/docs)
- [Documentación de Flutter](https://docs.flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Database Functions](https://supabase.com/docs/guides/database/functions)

---

## Licencia

Este proyecto es de código privado. Todos los derechos reservados.

---

**Última actualización:** Junio 2026
