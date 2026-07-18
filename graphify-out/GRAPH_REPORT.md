# Graph Report - applicoresestacion  (2026-07-17)

## Corpus Check
- 126 files · ~62,309 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1357 nodes · 1813 edges · 102 communities (92 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8374ac95`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- order_providers.dart
- order_create_view.dart
- order_repository.dart
- order_detail_view.dart
- customer_form_view.dart
- product_form_view.dart
- product_providers.dart
- customer_providers.dart
- customer_detail_view.dart
- printer_provider.dart
- bluetooth_printer_service_io.dart
- orders_view.dart
- AppDelegate
- responsive.dart
- printer_settings_view.dart
- router.dart
- productsProvider
- json_helpers.dart
- customer_repository.dart
- printer_service.dart
- dashboard_view.dart
- supabase_health_check_view.dart
- app_config.dart
- login_view.dart
- supabase_health_check_service.dart
- category_repository.dart
- order_item.dart
- package:go_router/go_router.dart
- window_size_service_web.dart
- product_detail_view.dart
- package:flutter/material.dart
- _PrinterSettingsViewState
- brand_repository.dart
- serial_printer_service_io.dart
- customers_view.dart
- customer_basket_repository.dart
- wWinMain
- product_repository.dart
- windows_printer_service_io.dart
- order.dart
- _OrderDetailViewState
- order_extensions.dart
- supabase_service.dart
- payment.dart
- manifest.json
- @freezed
- ConsumerState
- serial_printer_service_web.dart
- products_view.dart
- payment_providers.dart
- theme.dart
- _CustomerDetailViewState
- customer.dart
- product.dart
- State
- main.dart
- auth_service.dart
- windows_printer_service_web.dart
- bluetooth_printer_service_web.dart
- bool get
- customersProvider
- currentOrderCartProvider
- config/supabase_config.dart
- package:supabase_flutter/supabase_flutter.dart
- StateNotifier
- PrinterService
- package:flutter_riverpod/flutter_riverpod.dart
- json_helpers.dart
- package:freezed_annotation/freezed_annotation.dart
- MainActivity
- graphify.js
- bluetooth_printer_service_io.dart
- serial_printer_service.dart
- windows_printer_service.dart
- @licoreria
- String?
- package:flutter_riverpod/flutter_riverpod.dart
- payment_form_dialog.dart
- Requerimientos Funcionales
- 3. Módulo de Pedidos y Ventas
- add_remove_button.dart
- 7. Módulo Financiero y de Caja
- 8. Módulo de Reportes y Analytics
- 10. Configuración y Personalización
- 2. Módulo de Productos e Inventario
- 4. Módulo de Clientes
- _CustomerFormViewState
- package:go_router/go_router.dart
- 12. Notificaciones Push
- 1. Roles y Permisos
- 5. Módulo de Domicilios y Logística
- 6. Módulo de Proveedores
- 9. Sistema de Seguridad y Auditoría
- opencode.json
- AGENTS.md
- README.md

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `currentOrderCartProvider` - 18 edges
3. `Requerimientos Funcionales` - 16 edges
4. `productsProvider` - 14 edges
5. `MessageHandler` - 12 edges
6. `Sistema de Gestión para Licorería` - 11 edges
7. `Sistema de Gestión para Licorería - Documentación Completa` - 11 edges
8. `Queries Comunes` - 11 edges
9. `customersProvider` - 10 edges
10. `ordersProvider` - 10 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_cart_panel.dart → lib/data/providers/order_cart_providers.dart
- `_buildDeliverySection` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_cart_panel.dart → lib/data/providers/order_cart_providers.dart
- `_buildNotesSection` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_cart_panel.dart → lib/data/providers/order_cart_providers.dart
- `_onProductIncrement` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_catalog_panel.dart → lib/data/providers/order_cart_providers.dart
- `build` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_create_bottom_bar.dart → lib/data/providers/order_cart_providers.dart

## Import Cycles
- None detected.

## Communities (102 total, 10 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.06
Nodes (52): FlutterViewController, Point, RECT, Size, unique_ptr, DartProject, HWND, LPARAM (+44 more)

### Community 2 - "order_create_view.dart"
Cohesion: 0.11
Nodes (19): ../../../../core/responsive.dart, _addressController, _buildHeader, _buildMobileBody, _buildTypeSection, createState, _currentUserId, _deliveryFeeController (+11 more)

### Community 3 - "order_repository.dart"
Cohesion: 0.05
Nodes (44): ../../../../../domain/models/order.dart, ../../domain/models/order_extensions.dart, ../../../../../domain/models/order_item.dart, ReceiptGenerator, assignDeliveryPerson, cancel, _client, create (+36 more)

### Community 4 - "order_detail_view.dart"
Cohesion: 0.07
Nodes (27): _buildBottomBar, _buildCustomerInfo, _buildInfoChip, _buildItemCard, _buildMenuItems, _buildOrderHeader, _buildStatusChip, _canAssignDelivery (+19 more)

### Community 5 - "customer_form_view.dart"
Cohesion: 0.07
Nodes (27): FormState, _addressController, build, _buildSection, createState, _creditLimitController, _currentBalanceController, _currentUserId (+19 more)

### Community 6 - "product_form_view.dart"
Cohesion: 0.06
Nodes (31): _barcodeController, _buildSectionTitle, _codeController, _costController, createState, _descriptionController, dispose, _formKey (+23 more)

### Community 7 - "product_providers.dart"
Cohesion: 0.08
Nodes (25): ../../data/repositories/product_repository.dart, brandRepositoryProvider, categoryRepositoryProvider, clearFilters, copyWith, createProduct, deleteProduct, error (+17 more)

### Community 8 - "customer_providers.dart"
Cohesion: 0.07
Nodes (27): clearFilters, copyWith, createCustomer, customerBasketRepositoryProvider, customers, deleteCustomer, error, getBasketStats (+19 more)

### Community 9 - "customer_detail_view.dart"
Cohesion: 0.08
Nodes (24): _buildHeader, _buildInfoRow, _buildInfoTab, _buildSection, _buildStatItem, createState, customerId, dispose (+16 more)

### Community 10 - "printer_provider.dart"
Cohesion: 0.08
Nodes (23): dart:convert, _buildStaticDebugInfo, clear, config, isScanning, join, _key, lines (+15 more)

### Community 11 - "bluetooth_printer_service_io.dart"
Cohesion: 0.09
Nodes (22): BluetoothDevice?, FlutterThermalPrinter, connect, _connectedBtDevice, _connectedPrinter, disconnect, discoverDevices, _ignoredCharacteristicUuids (+14 more)

### Community 12 - "orders_view.dart"
Cohesion: 0.12
Nodes (20): ordersProvider, _saveOrder, _assignDeliveryPerson, _cancelOrder, build, _buildFilters, _buildInfoChip, _buildOrderCard (+12 more)

### Community 13 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 14 - "responsive.dart"
Cohesion: 0.10
Nodes (19): BuildContext, build, BuildContextResponsive, desktop, isDesktop, isMobile, isMobileOrTablet, isTablet (+11 more)

### Community 15 - "printer_settings_view.dart"
Cohesion: 0.10
Nodes (19): ../../../../data/providers/printer_provider.dart, ../../../../data/services/printer/printer_service.dart, _availableConnectionTypes, _buildDeviceScanner, _buildInfoCard, _buildSaveButton, _buildSerialConfig, _buildTestButton (+11 more)

### Community 16 - "router.dart"
Cohesion: 0.10
Nodes (19): GoRouter, router, ../ui/features/auth/views/login_view.dart, ../ui/features/customers/views/customer_detail_view.dart, ../ui/features/customers/views/customer_form_view.dart, ../ui/features/customers/views/customers_view.dart, ../ui/features/dashboard/views/dashboard_view.dart, ../ui/features/delivery/views/delivery_view.dart (+11 more)

### Community 17 - "productsProvider"
Cohesion: 0.12
Nodes (18): ../../../../data/repositories/brand_repository.dart, ../../../../data/repositories/category_repository.dart, productsProvider, initState, _onCategorySelected, _showDeleteDialog, _generateNextCode, _saveProduct (+10 more)

### Community 18 - "json_helpers.dart"
Cohesion: 0.12
Nodes (16): defaultValue, jsonBool, jsonDateTime, jsonDouble, jsonInt, jsonString, jsonStringRequired, parsed (+8 more)

### Community 19 - "customer_repository.dart"
Cohesion: 0.12
Nodes (15): ../../domain/models/customer_extensions.dart, _client, create, CustomerRepository, delete, getAll, getById, getByIdentification (+7 more)

### Community 20 - "printer_service.dart"
Cohesion: 0.12
Nodes (15): address, connect, connectionType, disconnect, discoverDevices, error, isConnected, message (+7 more)

### Community 21 - "dashboard_view.dart"
Cohesion: 0.12
Nodes (15): _authService, build, _buildContent, _buildError, _buildModuleCard, createState, _errorMessage, _getRoleColor (+7 more)

### Community 22 - "supabase_health_check_view.dart"
Cohesion: 0.06
Nodes (32): addItem, clearCart, copyWith, CurrentOrderCartNotifier, CurrentOrderCartState, customerAddress, customerId, customerName (+24 more)

### Community 23 - "app_config.dart"
Cohesion: 0.13
Nodes (14): AppConfig, appName, appVersion, defaultPageSize, reminderCriticalAlert, reminderFirstAlert, reminderPartialDeliveryAlert, reminderSecondAlert (+6 more)

### Community 24 - "login_view.dart"
Cohesion: 0.14
Nodes (13): ../../../../data/services/auth_service.dart, _authService, build, _buildUserChip, createState, dispose, _emailController, _errorMessage (+5 more)

### Community 25 - "supabase_health_check_service.dart"
Cohesion: 0.14
Nodes (13): Duration, _checkAuthStatus, _checkConnection, _checkInitialData, _checkTableAccess, _client, duration, message (+5 more)

### Community 26 - "category_repository.dart"
Cohesion: 0.14
Nodes (13): Category, CategoryRepository, _client, create, description, fromJson, getAll, iconUrl (+5 more)

### Community 27 - "order_item.dart"
Cohesion: 0.06
Nodes (35): ../../../../data/services/supabase_health_check_service.dart, double get, OrderItemListExtension, OrderItemSupabaseExtension, toRpcJson, toSupabaseJson, totalDiscount, totalQuantity (+27 more)

### Community 28 - "package:go_router/go_router.dart"
Cohesion: 0.22
Nodes (9): BarcodeScannerView, _BarcodeScannerViewState, build, _controller, createState, dispose, _hasScanned, MobileScannerController (+1 more)

### Community 29 - "window_size_service_web.dart"
Cohesion: 0.07
Nodes (26): dart:html, dart:math, getLastSize, initialize, _instance, saveSize, getLastSize, initialize (+18 more)

### Community 30 - "product_detail_view.dart"
Cohesion: 0.17
Nodes (12): ../../../../data/providers/product_providers.dart, productByIdProvider, build, _buildChip, _buildFeatureRow, _buildMarginInfo, _buildPriceRow, _buildProductDetail (+4 more)

### Community 31 - "package:flutter/material.dart"
Cohesion: 0.18
Nodes (10): ResponsiveBuilder, ResponsiveVisibility, LicoreriaApp, build, DeliveryView, build, ReportsView, SettingsView (+2 more)

### Community 32 - "_PrinterSettingsViewState"
Cohesion: 0.21
Nodes (13): isPrinterScanningProvider, printerConfigProvider, printerDevicesProvider, printTestPageProvider, selectedPrinterConnectionTypeProvider, build, _buildConnectionTypeSelector, initState (+5 more)

### Community 33 - "brand_repository.dart"
Cohesion: 0.15
Nodes (12): Brand, BrandRepository, _client, create, description, fromJson, getAll, id (+4 more)

### Community 34 - "serial_printer_service_io.dart"
Cohesion: 0.17
Nodes (11): dart:typed_data, connect, disconnect, discoverDevices, isConnected, _port, printBytes, printPdf (+3 more)

### Community 35 - "customers_view.dart"
Cohesion: 0.18
Nodes (10): ../../../../../domain/models/customer.dart, _buildCustomerCard, _buildInfoChip, _buildStatusBadge, createState, dispose, _getTypeColor, _getTypeIcon (+2 more)

### Community 36 - "customer_basket_repository.dart"
Cohesion: 0.17
Nodes (11): ../../domain/models/customer_basket.dart, ../../domain/models/customer_basket_extensions.dart, _client, create, CustomerBasketRepository, delete, getBasketStats, getByCustomer (+3 more)

### Community 37 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 38 - "product_repository.dart"
Cohesion: 0.15
Nodes (12): ../../../../domain/models/product.dart, _client, create, delete, getAll, getByBarcode, getByCode, getById (+4 more)

### Community 39 - "windows_printer_service_io.dart"
Cohesion: 0.18
Nodes (10): connect, disconnect, discoverDevices, isConnected, printBytes, printPdf, _selectedPrinter, supportsPdf (+2 more)

### Community 40 - "order.dart"
Cohesion: 0.06
Nodes (38): assignDeliveryPerson, cancelOrder, clearFilters, copyWith, createOrder, error, getById, getItems (+30 more)

### Community 41 - "_OrderDetailViewState"
Cohesion: 0.47
Nodes (6): orderByIdProvider, orderItemsProvider, printOrderReceiptProvider, build, _OrderDetailViewState, _printReceipt

### Community 42 - "order_extensions.dart"
Cohesion: 0.14
Nodes (14): add_remove_button.dart, _buildProductCard, createState, _defaultPriceType, dispose, _onProductIncrement, _onSearchChanged, OrderCatalogPanel (+6 more)

### Community 43 - "supabase_service.dart"
Cohesion: 0.18
Nodes (10): _client, delete, insert, insertMany, rpc, select, selectOne, subscribe (+2 more)

### Community 44 - "payment.dart"
Cohesion: 0.20
Nodes (11): ConsumerWidget, currentOrderCartProvider, build, _buildCustomerSection, initState, _selectCustomer, OrderCartPanel, _onProductDecrement (+3 more)

### Community 45 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 46 - "@freezed"
Cohesion: 0.22
Nodes (11): brandsProvider, categoriesProvider, productRepositoryProvider, build, build, _loadProduct, ProductFormView, _ProductFormViewState (+3 more)

### Community 47 - "ConsumerState"
Cohesion: 0.04
Nodes (47): 1. Clonar el repositorio, 2. Configurar Supabase, 3. Instalar dependencias, 4. Generar código (Freezed, JSON Serializable), 5. Ejecutar la aplicación, Arquitectura del Proyecto, Comandos Útiles, ✅ Configuración Base (+39 more)

### Community 48 - "serial_printer_service_web.dart"
Cohesion: 0.22
Nodes (8): ../../../../domain/models/printer_config.dart, connect, disconnect, discoverDevices, isConnected, printBytes, printPdf, supportsPdf

### Community 49 - "products_view.dart"
Cohesion: 0.07
Nodes (27): 10. Reporte de Auditoría (Acciones de Usuario), 1. Crear Proyecto, 1. Obtener Productos con Stock Bajo, 2. Ejecutar el Schema, 2. Ventas del Día por Vendedor, 3. Clientes con Deudas Vencidas, 3. Configurar Autenticación, 4. Crear Usuarios de Prueba (+19 more)

### Community 50 - "payment_providers.dart"
Cohesion: 0.22
Nodes (8): getByCustomer, getByOrder, paymentRepositoryProvider, paymentsByCustomerProvider, repository, PaymentRepository, _registerPayment, ../repositories/payment_repository.dart

### Community 51 - "theme.dart"
Cohesion: 0.20
Nodes (9): AppTheme, backgroundColor, errorColor, primaryColor, secondaryColor, successColor, surfaceColor, warningColor (+1 more)

### Community 52 - "_CustomerDetailViewState"
Cohesion: 0.22
Nodes (11): customerBasketsProvider, customerBasketStatsProvider, customerByIdProvider, customerOrdersHistoryProvider, customerStatsProvider, build, _buildBasketsTab, _buildOrdersTab (+3 more)

### Community 53 - "customer.dart"
Cohesion: 0.18
Nodes (10): addressController, build, _buildCartItem, _buildDeliverySection, _buildItemPriceTypeChip, _buildNotesSection, deliveryFeeController, notesController (+2 more)

### Community 54 - "product.dart"
Cohesion: 0.33
Nodes (5): ../../../../../data/providers/order_providers.dart, build, canSave, isLoading, onSave

### Community 55 - "State"
Cohesion: 0.32
Nodes (8): LoginView, _LoginViewState, DashboardView, _DashboardViewState, PaymentFormDialog, _PaymentFormDialogState, State, StatefulWidget

### Community 56 - "main.dart"
Cohesion: 0.22
Nodes (8): config/router.dart, config/theme.dart, data/services/window_size/window_size_service.dart, build, initialize, main, _waitForInitialSession, package:flutter/foundation.dart

### Community 57 - "auth_service.dart"
Cohesion: 0.20
Nodes (9): ../../../../domain/models/user.dart, AuthService, authStateChanges, _client, getCurrentUser, signIn, signOut, Stream (+1 more)

### Community 58 - "windows_printer_service_web.dart"
Cohesion: 0.20
Nodes (9): dart:async, connect, disconnect, discoverDevices, isConnected, printBytes, printPdf, supportsPdf (+1 more)

### Community 59 - "bluetooth_printer_service_web.dart"
Cohesion: 0.22
Nodes (8): connect, disconnect, discoverDevices, isConnected, printBytes, printPdf, supportsPdf, package:pdf/widgets.dart

### Community 60 - "bool get"
Cohesion: 0.25
Nodes (7): bool get, customer_basket.dart, int get, hasPending, isFullyReturned, pendingQuantity, toSupabaseJson

### Community 61 - "customersProvider"
Cohesion: 0.25
Nodes (8): customersProvider, _save, build, _buildCustomersList, _buildFilters, build, initState, Route /customers/create

### Community 62 - "currentOrderCartProvider"
Cohesion: 0.17
Nodes (11): _, class, ../../../../../data/providers/customer_providers.dart, cancelled, createState, customer, CustomerSelectionResult, dispose (+3 more)

### Community 63 - "config/supabase_config.dart"
Cohesion: 0.25
Nodes (7): config/supabase_config.dart, _client, create, delete, getByCustomer, getByOrder, _handleError

### Community 66 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.29
Nodes (6): app_config.dart, client, initialize, SupabaseConfig, package:supabase_flutter/supabase_flutter.dart, static SupabaseClient get

### Community 67 - "StateNotifier"
Cohesion: 0.67
Nodes (3): CustomersNotifier, CustomersState, StateNotifier

### Community 68 - "PrinterService"
Cohesion: 0.29
Nodes (7): BluetoothPrinterService, BluetoothPrinterService, PrinterService, SerialPrinterService, SerialPrinterService, WindowsPrinterService, WindowsPrinterService

### Community 69 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.24
Nodes (8): ../../../../../data/providers/user_providers.dart, client, data, deliveryUsersProvider, map, build, DeliveryPersonSelectorDialog, package:flutter_riverpod/flutter_riverpod.dart

### Community 70 - "json_helpers.dart"
Cohesion: 0.06
Nodes (45): @freezed, customer.dart, json_helpers.dart, BasketStatus, _basketStatusFromDb, BasketStatusX, CustomerBasket, CustomerBasketSupabaseExtension (+37 more)

### Community 72 - "package:freezed_annotation/freezed_annotation.dart"
Cohesion: 0.47
Nodes (5): PrinterConfigNotifier, fromJson, PrinterConfig, PrinterConnectionType, PrinterConnectionTypeX

### Community 85 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.33
Nodes (6): ../../../../../data/providers/payment_providers.dart, ../../../../../domain/models/payment.dart, paymentsByOrderProvider, build, orderId, PaymentsDialog

### Community 86 - "payment_form_dialog.dart"
Cohesion: 0.18
Nodes (11): OrderSupabaseExtension, Order, _amountController, build, createState, dispose, _method, _notesController (+3 more)

### Community 87 - "Requerimientos Funcionales"
Cohesion: 0.20
Nodes (10): 11.1 Funcionamiento Sin Internet, 11.2 Sincronización, 11. Arquitectura Offline-First, 13.1 WhatsApp, 13.2 Mapas, 13.3 Impresora Térmica Bluetooth, 13. Integraciones, 14. Módulos Futuros (Nice-to-Have) (+2 more)

### Community 88 - "3. Módulo de Pedidos y Ventas"
Cohesion: 0.22
Nodes (9): 3.1 Registro de Pedidos, 3.2 Estados del Pedido, 3.3 Facturación e Impresión, 3.4 Cotizaciones, 3.5 Edición de Pedidos, 3.6 Cancelación de Pedidos, 3.7 Entregas Parciales y Pendientes, 3.8 Sistema de Recordatorios de Pedidos (+1 more)

### Community 89 - "add_remove_button.dart"
Cohesion: 0.29
Nodes (6): IconData, AddRemoveButton, build, icon, onPressed, VoidCallback

### Community 90 - "7. Módulo Financiero y de Caja"
Cohesion: 0.29
Nodes (7): 7.1 Control de Caja, 7.2 Cierre Diario, 7.3 Caja Fuerte, 7.4 Cierre Semanal, 7.5 Gastos Diarios, 7.6 Reembolsos y Notas Crédito, 7. Módulo Financiero y de Caja

### Community 91 - "8. Módulo de Reportes y Analytics"
Cohesion: 0.33
Nodes (6): 8.1 Dashboard en Tiempo Real (Administrador), 8.2 Reportes de Ventas, 8.3 Reportes Financieros, 8.4 Reportes de Inventario, 8.5 Exportación, 8. Módulo de Reportes y Analytics

### Community 92 - "10. Configuración y Personalización"
Cohesion: 0.40
Nodes (5): 10.1 Datos del Negocio, 10.2 Configuración de Factura, 10.3 Configuración General, 10.4 Configuración de Notificaciones, 10. Configuración y Personalización

### Community 93 - "2. Módulo de Productos e Inventario"
Cohesion: 0.40
Nodes (5): 2.1 Catálogo de Productos, 2.2 Escaneo y Búsqueda, 2.3 Movimientos de Inventario, 2.4 Alertas y Notificaciones, 2. Módulo de Productos e Inventario

### Community 94 - "4. Módulo de Clientes"
Cohesion: 0.40
Nodes (5): 4.1 Registro de Clientes, 4.2 Clientes a Crédito, 4.3 Control de Canastas Retornables, 4.4 Cliente Consignatario (Caso Especial), 4. Módulo de Clientes

### Community 95 - "_CustomerFormViewState"
Cohesion: 0.22
Nodes (11): ConsumerState, ConsumerStatefulWidget, customerRepositoryProvider, CustomerFormView, _CustomerFormViewState, _loadCustomer, CustomersView, _CustomersViewState (+3 more)

### Community 96 - "package:go_router/go_router.dart"
Cohesion: 0.50
Nodes (3): build, package:go_router/go_router.dart, Route /settings/printer

### Community 97 - "12. Notificaciones Push"
Cohesion: 0.50
Nodes (4): 12.1 Para el Domiciliario, 12.2 Para el Administrador, 12.3 Para el Vendedor, 12. Notificaciones Push

### Community 98 - "1. Roles y Permisos"
Cohesion: 0.50
Nodes (4): 1.1 Vendedor (Punto de Venta), 1.2 Domiciliario, 1.3 Administrador (Dueño), 1. Roles y Permisos

### Community 99 - "5. Módulo de Domicilios y Logística"
Cohesion: 0.50
Nodes (4): 5.1 Gestión de Domicilios, 5.2 Vista del Domiciliario, 5.3 Tracking en Tiempo Real, 5. Módulo de Domicilios y Logística

### Community 100 - "6. Módulo de Proveedores"
Cohesion: 0.50
Nodes (4): 6.1 Registro de Proveedores, 6.2 Facturas de Proveedores, 6.3 Pagos a Proveedores, 6. Módulo de Proveedores

### Community 101 - "9. Sistema de Seguridad y Auditoría"
Cohesion: 0.50
Nodes (4): 9.1 Autenticación, 9.2 Logs de Auditoría, 9.3 Permisos Granulares, 9. Sistema de Seguridad y Auditoría

### Community 102 - "opencode.json"
Cohesion: 0.50
Nodes (3): plugin, $schema, .opencode/plugins/graphify.js

## Knowledge Gaps
- **794 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `XCTest`, `AppConfig`, `appName` (+789 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CustomerType` connect `json_helpers.dart` to `customer_providers.dart`, `customer_form_view.dart`, `supabase_health_check_view.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `Sistema de Gestión para Licorería - Documentación Completa` connect `ConsumerState` to `products_view.dart`, `Requerimientos Funcionales`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `SaleType` connect `order.dart` to `order_create_view.dart`, `supabase_health_check_view.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `$schema`, `.opencode/plugins/graphify.js`, `XCTest` to the rest of the system?**
  _794 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.06271186440677966 - nodes in this community are weakly interconnected._
- **Should `order_create_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `order_repository.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04698581560283688 - nodes in this community are weakly interconnected._