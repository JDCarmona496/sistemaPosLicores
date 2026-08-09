# Notas Técnicas - Applicoresestacion

## Dependencias

### mobile_scanner
- **Versión actual:** 7.3.0
- **Estado:** Advertencia de Kotlin Gradle Plugin (KGP)
- **Descripción:** El plugin aún no ha migrado a Built-in Kotlin de Flutter. Esto genera una advertencia durante el build pero no afecta la funcionalidad.
- **Acción:** Esperar a que el equipo de mobile_scanner publique una versión con soporte para Built-in Kotlin. La versión 7.2.1 menciona que están preparando compatibilidad con AGP 9.
- **Referencia:** https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

### fl_chart
- **Uso:** gráficos del módulo de reportes (líneas, barras, dona).
- **Estado:** Estable.
- **Nota:** la API varía entre versiones; usar siempre los constructores de datos actuales (`FlGridData`, `LineTouchTooltipData`, etc.) y verificar con `flutter analyze` después de actualizar el paquete.

## Módulo de Reportes

- **Librería:** `fl_chart` para gráficos de líneas, barras y dona.
- **Backend:** funciones RPC en Supabase (`get_sales_summary`, `get_sales_trend`, `get_sales_by_payment_method`, `get_top_products`, `get_hourly_sales`, `get_sales_by_seller`, `get_pending_orders_summary`).
- **Arquitectura Flutter:**
  - `ReportsRepository` (`lib/data/repositories/reports_repository.dart`) consume las RPC.
  - `ReportsNotifier` (`lib/data/providers/reports_providers.dart`) carga todos los reportes en paralelo y filtra por vendedor cuando el usuario no es admin.
  - Vistas:
    - `DashboardReportsView`: KPIs, tendencia, métodos de pago, ventas por hora y por vendedor.
    - `SalesReportView`: resumen financiero, tendencia y desglose por pago/vendedor.
    - `ProductsReportView`: top productos vendidos.
- **Filtro:** selector de rango de fechas con presets (hoy, 7 días, 30 días) y pickers personalizados.
- **Estilo:** widgets comparten paleta y estilos en `chart_styles.dart`; tarjetas redondeadas, grillas tenues y tipografía minimalista.

## Manejo de Fecha y Hora

- **Fuente de verdad:** el servidor de Supabase (`now()`). Nunca se confía ciegamente en el reloj del dispositivo para timestamps que se persisten.
- **Sincronización:** `ServerTimeService` (`lib/data/services/server_time_service.dart`) consulta la función RPC `get_server_time()` una vez y cachea el desfase para usarlo sin más llamadas de red.
- **Triggers de BD:** en `orders`, `order_items` y `payments` se aseguran que `created_at`, `updated_at`, `delivered_at` y `cancelled_at` usen `now()` cuando no se envíe un valor explícito.
- **Visualización:** todo timestamp proveniente de la base de datos se convierte a hora local con `.toLocal()` antes de mostrarse en UI o facturas.
- **Migración relevante:** `opencode/migrations/20260808_server_time_triggers.sql`.

## Arquitectura

### Estructura del Proyecto
- **UI:** Flutter con Riverpod para gestión de estado
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Impresión:** ESC/POS para impresoras térmicas (58mm, 203dpi)
- **Geocoding:** Nominatim (OpenStreetMap) para geocodificación de direcciones

### Módulos Principales
1. **Productos:** Gestión de inventario con escaneo de códigos de barras
2. **Pedidos:** Creación y gestión de órdenes con múltiples tipos de precio
3. **Entregas:** Sistema de domicilios con evidencia de entrega (firma + coordenadas)
4. **Clientes:** Base de datos de clientes con historial de pedidos
5. **Reportes:** Análisis de ventas y métricas de negocio

## Configuración

### Supabase
- **URL:** https://afmmyqzkbhpgljdqitzl.supabase.co
- **Anon Key:** Configurada en `lib/config/app_config.dart`
- **RLS:** 33 políticas de seguridad + 34 reglas RLS activas
- **Storage:** Bucket `delivery-evidence` para evidencias de entrega

### Geocoding
- **Servicio:** Nominatim (OpenStreetMap)
- **Zona de operación:** Cerrito, Valle del Cauca, Colombia
- **Configuración:** Persistida en SharedPreferences, editable desde Configuración

## Problemas Conocidos

### Escáner de Código de Barras
- **Problema:** Detección duplicada de códigos de barras
- **Solución:** Implementado flag `_isProcessing` en `ProductBarcodeScannerModal` para evitar detecciones simultáneas
- **Estado:** ✅ Resuelto

### Layout de Formularios
- **Problema:** Errores de layout en pantallas móviles (RenderFlex overflow)
- **Solución:** Reestructurado `_buildBrandCategoryRow` y `_buildInventoryCard` para usar Column en pantallas estrechas (< 500px)
- **Estado:** ✅ Resuelto

### Fechas incorrectas en facturas
- **Problema:** Las facturas mostraban horas desfasadas porque los timestamps de Supabase (UTC) se imprimían sin convertir a hora local, y en algunos flujos fallback se usaba `DateTime.now()` del dispositivo.
- **Solución:**
  - Todos los timestamps de BD se formatean con `.toLocal()` antes de mostrarse o imprimirse.
  - Los triggers de BD ahora asignan `now()` del servidor para `created_at`, `updated_at`, `delivered_at` y `cancelled_at`.
  - `ServerTimeService` sincroniza la app con la hora del servidor cuando se requiere un timestamp desde Flutter.
- **Estado:** ✅ Resuelto

## Próximos Pasos
- Monitorear actualizaciones de `mobile_scanner` para Built-in Kotlin
- Implementar más pruebas unitarias para módulos de pedidos y entregas
- Optimizar rendimiento de consultas en tablas con muchos registros
