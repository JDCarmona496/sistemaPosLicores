# Sistema de Gestión para Licorería

Aplicación multiplataforma (iOS, Android, Web, Windows) para la gestión integral de una licorería con control de inventario, ventas, clientes, domicilios, proveedores y financiero.

## Características

- **Multiplataforma**: iOS, Android, Web, Windows desde un solo código
- **Multi-rol**: Vendedor, Domiciliario, Administrador con permisos diferenciados
- **Impresión Bluetooth**: Soporte para impresoras térmicas ESC/POS
- **Offline-first**: Funciona sin internet, sincroniza cuando hay conexión
- **Tiempo real**: Sincronización en vivo entre dispositivos
- **Escaneo de códigos de barras**: Búsqueda rápida de productos
- **Control de inventario**: Stock, lotes, vencimientos, alertas
- **Gestión de clientes**: Crédito, canastas retornables, fidelización
- **Domicilios**: Asignación, tracking, foto de entrega
- **Reportes**: Dashboard con KPIs, reportes avanzados
- **Edición y cancelación de pedidos**: Con auditoría completa
- **Entregas parciales**: Registro de productos entregados vs pendientes
- **Recordatorios automáticos**: Notificaciones de pedidos pendientes

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
| Gráficos | fl_chart |

## Requisitos

- Flutter SDK 3.12.1 o superior
- Dart SDK 3.12.1 o superior
- Cuenta de Supabase (gratuita)

## Instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd applicoresestacion
```

### 2. Configurar Supabase

1. Crear proyecto en [supabase.com](https://supabase.com)
2. Ejecutar el schema SQL en `opencode/licoreria-database-schema.sql`
3. Ejecutar las migraciones de `opencode/migrations/` en orden cronológico:
   - `20260808_shifts_rls.sql`
   - `20260808_cash_counts.sql`
   - `20260808_reports_rpc.sql`
   - `20260808_server_time_triggers.sql`
4. Configurar las credenciales en `lib/config/app_config.dart`:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'tu_anon_key';
```

O crear archivo `.env`:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Generar código (Freezed, JSON Serializable)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Crear usuarios de prueba

Ejecutar en Supabase SQL Editor:

```sql
-- Admin
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'admin@licoreria.com',
  crypt('Admin123!', gen_salt('bf')),
  now(),
  '{"full_name": "Administrador", "role": "admin"}'::jsonb,
  now(), now()
);

-- Vendedor
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'vendedor@licoreria.com',
  crypt('Vendedor123!', gen_salt('bf')),
  now(),
  '{"full_name": "Juan Vendedor", "role": "seller"}'::jsonb,
  now(), now()
);

-- Domiciliario
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'domiciliario@licoreria.com',
  crypt('Domiciliario123!', gen_salt('bf')),
  now(),
  '{"full_name": "Pedro Domiciliario", "role": "delivery"}'::jsonb,
  now(), now()
);
```

### 6. Ejecutar la aplicación

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

## Estructura del Proyecto

```
lib/
├── config/              # Configuración global
├── data/                # Capa de datos
│   ├── models/          # Modelos de API/BD
│   ├── repositories/    # Repositorios
│   └── services/        # Servicios
├── domain/              # Capa de dominio
│   ├── models/          # Modelos de dominio
│   └── use_cases/       # Casos de uso
└── ui/                  # Capa de presentación
    ├── core/            # Componentes compartidos
    └── features/        # Features por módulo
        ├── auth/
        ├── dashboard/
        ├── orders/
        ├── products/
        ├── customers/
        ├── delivery/
        ├── reports/
        └── settings/
```

## Comandos Útiles

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
```

## Roles y Permisos

| Rol | Permisos |
|-----|----------|
| **Admin** | Acceso completo: inventario, proveedores, financiero, reportes, configuración |
| **Seller** | Ventas, clientes, inventario básico, gastos del día |
| **Delivery** | Ver pedidos asignados, actualizar estados, tomar foto de entrega |

## Notas Importantes

- **Módulo de Reportes**: implementado con `fl_chart`. Consulta las funciones RPC de reportes en `opencode/migrations/20260808_reports_rpc.sql`.
- **Fecha y hora**: la fuente de verdad es el servidor de Supabase (`now()`). La app sincroniza con `ServerTimeService` y muestra los timestamps en hora local usando `.toLocal()`.

## Documentación

Toda la documentación del proyecto está consolidada en un solo archivo:

📄 **[Documentación Completa](opencode/documentacion-completa.md)**

Este documento incluye:
- Requerimientos funcionales completos
- Arquitectura del proyecto Flutter
- Guía de configuración de Supabase
- Queries SQL comunes
- Guía de desarrollo y comandos útiles
- Próximos pasos del proyecto

## Licencia

Este proyecto es de código privado. Todos los derechos reservados.

## Soporte

Para preguntas o problemas, contactar al equipo de desarrollo.
