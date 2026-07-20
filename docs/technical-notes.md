# Notas Técnicas - Applicoresestacion

## Dependencias

### mobile_scanner
- **Versión actual:** 7.3.0
- **Estado:** Advertencia de Kotlin Gradle Plugin (KGP)
- **Descripción:** El plugin aún no ha migrado a Built-in Kotlin de Flutter. Esto genera una advertencia durante el build pero no afecta la funcionalidad.
- **Acción:** Esperar a que el equipo de mobile_scanner publique una versión con soporte para Built-in Kotlin. La versión 7.2.1 menciona que están preparando compatibilidad con AGP 9.
- **Referencia:** https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

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

## Próximos Pasos
- Monitorear actualizaciones de `mobile_scanner` para Built-in Kotlin
- Implementar más pruebas unitarias para módulos de pedidos y entregas
- Optimizar rendimiento de consultas en tablas con muchos registros
