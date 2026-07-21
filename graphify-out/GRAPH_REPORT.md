# Graph Report - applicoresestacion  (2026-07-21)

## Corpus Check
- 153 files · ~78,664 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1932 nodes · 2674 edges · 160 communities (146 shown, 14 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9054c9d5`
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
- product_barcode_scanner_modal.dart
- delivery_signature_dialog.dart
- package:supabase_flutter/supabase_flutter.dart
- StateNotifier
- PrinterService
- package:flutter_riverpod/flutter_riverpod.dart
- json_helpers.dart
- quantity_selector.dart
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
- order_repository.dart
- delivery_view.dart
- location_service.dart
- delivery_order_detail_view.dart
- signature_pad.dart
- delivery_order_card.dart
- delivery_zone_group_card.dart
- Notas Técnicas - Applicoresestacion
- ordersProvider
- order_zone_grouper.dart
- supabase_health_check_view.dart
- order_filter_bar.dart
- order.dart
- normalizar-stock-y-cantidades.sql
- delivery_evidence_service.dart
- settings_providers.dart
- delivery_items_dialog.dart
- categoriesProvider
- customer.dart
- product.dart
- fix-fractional-quantities.sql
- Sistema de Gestión para Licorería
- @freezed
- geocode_customer_address_button.dart
- route_optimizer.dart
- order_extensions.dart
- Arquitectura del Proyecto
- Funciones Útiles
- window_size_service.dart
- window_size_service_stub.dart
- Sistema de Gestión para Licorería - Documentación Completa
- Configuración Inicial en Supabase
- Instalación
- json_helpers.dart
- Próximos Pasos
- add-fractional-price-flag.sql
- fix-user-creation.sql
- fix-product-stock-numeric.sql
- renombrar-precio-fraccionado-a-frio.sql

## God Nodes (most connected - your core abstractions)
1. `public.profiles` - 23 edges
2. `Win32Window` - 22 edges
3. `currentOrderCartProvider` - 20 edges
4. `ordersProvider` - 20 edges
5. `Requerimientos Funcionales` - 16 edges
6. `productsProvider` - 14 edges
7. `customersProvider` - 12 edges
8. `MessageHandler` - 12 edges
9. `public.handle_updated_at()` - 11 edges
10. `public.orders` - 11 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/geocode_address_button.dart → lib/data/providers/order_cart_providers.dart
- `_confirmClearCart` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_cart_panel.dart → lib/data/providers/order_cart_providers.dart
- `build` --references--> `currentOrderCartProvider`  [EXTRACTED]
  lib/ui/features/orders/views/widgets/order_create_bottom_bar.dart → lib/data/providers/order_cart_providers.dart
- `_editGeocodingContext` --references--> `geocodingContextProvider`  [EXTRACTED]
  lib/ui/features/settings/views/settings_view.dart → lib/data/providers/settings_providers.dart
- `OrderItemSupabaseExtension` --extends--> `OrderItem`  [EXTRACTED]
  lib/domain/models/order_extensions.dart → lib/domain/models/order_item.dart

## Import Cycles
- None detected.

## Communities (160 total, 14 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.06
Nodes (52): FlutterViewController, Point, RECT, Size, unique_ptr, DartProject, HWND, LPARAM (+44 more)

### Community 2 - "order_create_view.dart"
Cohesion: 0.11
Nodes (19): ../../../../data/providers/printer_provider.dart, _addressController, _buildHeader, _buildMobileBody, _buildTypeSection, createState, _currentUserId, _deliveryFeeController (+11 more)

### Community 3 - "order_repository.dart"
Cohesion: 0.10
Nodes (20): ../../../../../domain/models/order.dart, ReceiptGenerator, EscPosReceiptGenerator, _formatMoney, generateOrderReceipt, generateTestPage, _truncate, _buildItemRow (+12 more)

### Community 4 - "order_detail_view.dart"
Cohesion: 0.05
Nodes (41): ../../../../../data/providers/payment_providers.dart, ../../../../../domain/models/payment.dart, getByCustomer, getByOrder, paymentRepositoryProvider, paymentsByCustomerProvider, paymentsByOrderProvider, repository (+33 more)

### Community 5 - "customer_form_view.dart"
Cohesion: 0.07
Nodes (28): FormState, _addressController, build, _buildSection, createState, _creditLimitController, _currentBalanceController, _currentUserId (+20 more)

### Community 6 - "product_form_view.dart"
Cohesion: 0.05
Nodes (41): _barcodeController, _buildBasicInfoCard, _buildBrandCategoryRow, _buildDescriptionCard, _buildInventoryCard, _buildInventoryField, _buildPackagingCard, _buildPricesCard (+33 more)

### Community 7 - "product_providers.dart"
Cohesion: 0.09
Nodes (23): ../../data/repositories/product_repository.dart, clearFilters, copyWith, createProduct, deleteProduct, error, getAll, getByBarcode (+15 more)

### Community 8 - "customer_providers.dart"
Cohesion: 0.07
Nodes (30): clearFilters, copyWith, createCustomer, customerBasketRepositoryProvider, customers, CustomersNotifier, CustomersState, deleteCustomer (+22 more)

### Community 9 - "customer_detail_view.dart"
Cohesion: 0.08
Nodes (23): _buildHeader, _buildInfoRow, _buildInfoTab, _buildSection, _buildStatItem, createState, customerId, dispose (+15 more)

### Community 10 - "printer_provider.dart"
Cohesion: 0.06
Nodes (34): _buildStaticDebugInfo, checkConnection, clear, config, _connectionSubscription, _createService, dispose, _disposeCurrentService (+26 more)

### Community 11 - "bluetooth_printer_service_io.dart"
Cohesion: 0.06
Nodes (34): BluetoothDevice?, FlutterThermalPrinter, _bleConnectionSubscription, connect, _connectBle, _connectedBleDevice, _connectedUsbPrinter, connectionState (+26 more)

### Community 12 - "orders_view.dart"
Cohesion: 0.11
Nodes (19): build, _buildEmptyState, _buildFlatList, _buildNoZonesNotice, _buildViewModeSelector, _buildWithoutLocationHeader, _buildZoneList, createState (+11 more)

### Community 13 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 14 - "responsive.dart"
Cohesion: 0.05
Nodes (35): BuildContext, build, BuildContextResponsive, desktop, isDesktop, isMobile, isMobileOrTablet, isTablet (+27 more)

### Community 15 - "printer_settings_view.dart"
Cohesion: 0.09
Nodes (22): Color, ../../../../data/services/printer/printer_service.dart, _availableConnectionTypes, _buildConnectionStatusCard, _buildDeviceScanner, _buildDisconnectButton, _buildInfoCard, _buildSaveButton (+14 more)

### Community 16 - "router.dart"
Cohesion: 0.09
Nodes (22): GoRouter, router, ../ui/features/auth/views/login_view.dart, ../ui/features/customers/views/customer_detail_view.dart, ../ui/features/customers/views/customer_form_view.dart, ../ui/features/customers/views/customers_view.dart, ../ui/features/dashboard/views/dashboard_view.dart, ../ui/features/delivery/views/delivery_order_detail_view.dart (+14 more)

### Community 17 - "productsProvider"
Cohesion: 0.11
Nodes (20): productsProvider, initState, _onCategorySelected, _showDeleteDialog, _generateNextCode, _saveProduct, build, _buildFilters (+12 more)

### Community 18 - "json_helpers.dart"
Cohesion: 0.06
Nodes (58): audit_customers, audit_inventory_movements, audit_orders, audit_payments, audit_products, on_auth_user_created, on_brand_updated, on_category_updated (+50 more)

### Community 19 - "customer_repository.dart"
Cohesion: 0.12
Nodes (16): ../../domain/models/customer_extensions.dart, _client, create, CustomerRepository, delete, getAll, getById, getByIdentification (+8 more)

### Community 20 - "printer_service.dart"
Cohesion: 0.11
Nodes (17): address, connect, connectionState, connectionType, disconnect, discoverDevices, dispose, error (+9 more)

### Community 21 - "dashboard_view.dart"
Cohesion: 0.12
Nodes (15): _authService, build, _buildContent, _buildError, _buildModuleCard, createState, _errorMessage, _getRoleColor (+7 more)

### Community 22 - "supabase_health_check_view.dart"
Cohesion: 0.05
Nodes (38): addItem, clearCart, copyWith, CurrentOrderCartNotifier, CurrentOrderCartState, customerAddress, customerId, customerName (+30 more)

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
Cohesion: 0.13
Nodes (14): Category, CategoryRepository, _client, create, description, fromJson, getAll, iconUrl (+6 more)

### Community 27 - "order_item.dart"
Cohesion: 0.22
Nodes (10): dbValue, fromJson, isColdPrice, isFullyDelivered, isWholesalePrice, OrderItem, OrderItemExtension, _orderItemPriceTypeFromDb (+2 more)

### Community 28 - "package:go_router/go_router.dart"
Cohesion: 0.22
Nodes (9): BarcodeScannerView, _BarcodeScannerViewState, build, _controller, createState, dispose, _hasScanned, MobileScannerController (+1 more)

### Community 29 - "window_size_service_web.dart"
Cohesion: 0.18
Nodes (10): dart:async, dart:html, _debounce, getLastSize, _heightKey, initialize, _onResize, saveSize (+2 more)

### Community 30 - "product_detail_view.dart"
Cohesion: 0.14
Nodes (14): ../../../../domain/models/product.dart, productByIdProvider, _buildCartItem, OrderCartPanel, build, _buildChip, _buildFeatureRow, _buildMarginInfo (+6 more)

### Community 31 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (16): IconData, ResponsiveBuilder, ResponsiveVisibility, LicoreriaApp, DeliveryZoneGroupCard, AddRemoveButton, build, icon (+8 more)

### Community 32 - "_PrinterSettingsViewState"
Cohesion: 0.15
Nodes (18): isPrinterScanningProvider, printerConfigProvider, printerConnectionStatusProvider, printerDevicesProvider, printerServiceProvider, printTestPageProvider, selectedPrinterConnectionTypeProvider, build (+10 more)

### Community 33 - "brand_repository.dart"
Cohesion: 0.14
Nodes (13): Brand, BrandRepository, _client, create, description, fromJson, getAll, id (+5 more)

### Community 34 - "serial_printer_service_io.dart"
Cohesion: 0.10
Nodes (19): _activePort, connect, connectionState, _connectionStateController, disconnect, discoverDevices, dispose, isConnected (+11 more)

### Community 35 - "customers_view.dart"
Cohesion: 0.11
Nodes (20): ../../../../../domain/models/customer.dart, customersProvider, _save, build, _buildCustomerCard, _buildCustomersList, _buildFilters, _buildInfoChip (+12 more)

### Community 36 - "customer_basket_repository.dart"
Cohesion: 0.17
Nodes (11): ../../domain/models/customer_basket.dart, ../../domain/models/customer_basket_extensions.dart, _client, create, CustomerBasketRepository, delete, getBasketStats, getByCustomer (+3 more)

### Community 37 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 38 - "product_repository.dart"
Cohesion: 0.17
Nodes (11): _client, create, delete, getAll, getByBarcode, getByCode, getById, getNextCode (+3 more)

### Community 39 - "windows_printer_service_io.dart"
Cohesion: 0.12
Nodes (15): connect, connectionState, _connectionStateController, disconnect, discoverDevices, dispose, isConnected, _lastConnectionState (+7 more)

### Community 40 - "order.dart"
Cohesion: 0.08
Nodes (25): assignDeliveryPerson, cancelOrder, clearFilters, copyWith, createOrder, error, getById, getItems (+17 more)

### Community 41 - "_OrderDetailViewState"
Cohesion: 0.29
Nodes (10): orderByIdProvider, orderItemsProvider, printOrderReceiptProvider, build, _DeliveryOrderDetailViewState, _markAllDelivered, _offerPrintReceipt, build (+2 more)

### Community 42 - "order_extensions.dart"
Cohesion: 0.13
Nodes (15): add_remove_button.dart, _buildProductCard, createState, _defaultPriceType, dispose, _onSearchChanged, OrderCatalogPanel, _OrderCatalogPanelState (+7 more)

### Community 43 - "supabase_service.dart"
Cohesion: 0.18
Nodes (10): _client, delete, insert, insertMany, rpc, select, selectOne, subscribe (+2 more)

### Community 44 - "payment.dart"
Cohesion: 0.06
Nodes (31): Client, dart:convert, http.Client, _client, displayName, _endpoint, geocode, GeocodingResult (+23 more)

### Community 45 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 46 - "@freezed"
Cohesion: 0.24
Nodes (10): ../../../../data/providers/product_providers.dart, ../../../../data/repositories/brand_repository.dart, brandRepositoryProvider, brandsProvider, build, BrandSettingsView, build, _showCreateDialog (+2 more)

### Community 47 - "ConsumerState"
Cohesion: 0.20
Nodes (10): 1. Clonar el repositorio, 2. Configurar Supabase, 3. Instalar dependencias, 4. Generar código (Freezed, JSON Serializable), 5. Ejecutar la aplicación, Comandos Útiles, Guía de Desarrollo, Instalación (+2 more)

### Community 48 - "serial_printer_service_web.dart"
Cohesion: 0.18
Nodes (10): connect, connectionState, disconnect, discoverDevices, dispose, isConnected, printBytes, printPdf (+2 more)

### Community 49 - "products_view.dart"
Cohesion: 0.18
Nodes (11): 10. Reporte de Auditoría (Acciones de Usuario), 1. Obtener Productos con Stock Bajo, 2. Ventas del Día por Vendedor, 3. Clientes con Deudas Vencidas, 4. Productos Más Vendidos (Últimos 30 días), 5. Cierre de Caja Diario, 6. Control de Canastas Retornables por Cliente, 7. Pedidos Pendientes para Domiciliario (+3 more)

### Community 50 - "payment_providers.dart"
Cohesion: 0.18
Nodes (11): _amountController, build, createState, dispose, _method, _notesController, order, PaymentFormDialog (+3 more)

### Community 51 - "theme.dart"
Cohesion: 0.20
Nodes (9): AppTheme, backgroundColor, errorColor, primaryColor, secondaryColor, successColor, surfaceColor, warningColor (+1 more)

### Community 52 - "_CustomerDetailViewState"
Cohesion: 0.22
Nodes (11): customerBasketsProvider, customerBasketStatsProvider, customerByIdProvider, customerOrdersHistoryProvider, customerStatsProvider, build, _buildBasketsTab, _buildOrdersTab (+3 more)

### Community 53 - "customer.dart"
Cohesion: 0.15
Nodes (12): geocode_address_button.dart, addressController, _buildEmptyState, _buildHeader, _buildItemPriceTypeChip, _confirmClearCart, deliveryFeeController, notesController (+4 more)

### Community 54 - "product.dart"
Cohesion: 0.14
Nodes (14): ConsumerWidget, ../../../../../data/providers/order_providers.dart, ../../../../../data/providers/user_providers.dart, deliveryUsersProvider, build, DeliveryPersonSelectorDialog, build, canSave (+6 more)

### Community 55 - "State"
Cohesion: 0.32
Nodes (8): LoginView, _LoginViewState, DashboardView, _DashboardViewState, SupabaseHealthCheckView, _SupabaseHealthCheckViewState, State, StatefulWidget

### Community 56 - "main.dart"
Cohesion: 0.22
Nodes (8): config/router.dart, config/theme.dart, data/services/window_size/window_size_service.dart, build, initialize, main, _waitForInitialSession, package:flutter/foundation.dart

### Community 57 - "auth_service.dart"
Cohesion: 0.25
Nodes (7): AuthService, authStateChanges, _client, getCurrentUser, signIn, signOut, Stream

### Community 58 - "windows_printer_service_web.dart"
Cohesion: 0.18
Nodes (10): ../../../../domain/models/printer_config.dart, connect, connectionState, disconnect, discoverDevices, dispose, isConnected, printBytes (+2 more)

### Community 59 - "bluetooth_printer_service_web.dart"
Cohesion: 0.18
Nodes (10): connect, connectionState, disconnect, discoverDevices, dispose, isConnected, printBytes, printPdf (+2 more)

### Community 60 - "bool get"
Cohesion: 0.25
Nodes (7): bool get, customer_basket.dart, int get, hasPending, isFullyReturned, pendingQuantity, toSupabaseJson

### Community 61 - "customersProvider"
Cohesion: 0.07
Nodes (29): activeOrders, copyWith, currentPosition, currentUser, deliveredOrders, DeliveryFilter, DeliveryFilterX, DeliveryOrdersNotifier (+21 more)

### Community 62 - "currentOrderCartProvider"
Cohesion: 0.17
Nodes (12): _, ../../../../../data/providers/customer_providers.dart, cancelled, createState, customer, CustomerSelectionResult, CustomerSelectorDialog, _CustomerSelectorDialogState (+4 more)

### Community 63 - "config/supabase_config.dart"
Cohesion: 0.25
Nodes (7): _client, create, delete, getByCustomer, getByOrder, _handleError, SupabaseClient get

### Community 64 - "product_barcode_scanner_modal.dart"
Cohesion: 0.08
Nodes (25): build, _buildCameraControls, _buildControlButton, _buildErrorPanel, _buildHeader, _buildOverlay, _buildPriceTile, _buildProductResult (+17 more)

### Community 65 - "delivery_signature_dialog.dart"
Cohesion: 0.05
Nodes (40): dart:io, ../../../../../data/services/delivery_evidence_service.dart, FocusNode, int?, orderRepositoryProvider, build, _confirm, createState (+32 more)

### Community 66 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.29
Nodes (6): app_config.dart, client, initialize, SupabaseConfig, package:supabase_flutter/supabase_flutter.dart, static SupabaseClient get

### Community 67 - "StateNotifier"
Cohesion: 0.33
Nodes (7): PrinterConfigNotifier, PrinterConnectionStatus, PrinterConnectionStatusNotifier, PrinterServiceManager, GeocodingContextNotifier, PrinterConfig, StateNotifier

### Community 68 - "PrinterService"
Cohesion: 0.29
Nodes (7): BluetoothPrinterService, BluetoothPrinterService, PrinterService, SerialPrinterService, SerialPrinterService, WindowsPrinterService, WindowsPrinterService

### Community 69 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.33
Nodes (5): config/supabase_config.dart, ../../../../domain/models/user.dart, client, data, map

### Community 70 - "json_helpers.dart"
Cohesion: 0.25
Nodes (10): fromJson, Payment, PaymentMethod, _paymentMethodFromDb, PaymentMethodX, PaymentStatus, _paymentStatusFromDb, PaymentStatusX (+2 more)

### Community 71 - "quantity_selector.dart"
Cohesion: 0.20
Nodes (10): currentOrderCartProvider, build, _buildCustomerSection, initState, _selectCustomer, build, _buildDeliverySection, _buildNotesSection (+2 more)

### Community 72 - "package:freezed_annotation/freezed_annotation.dart"
Cohesion: 0.24
Nodes (8): fromJson, PrinterConnectionType, PrinterConnectionTypeX, fromJson, UserRole, _userRoleFromDb, UserRoleX, package:freezed_annotation/freezed_annotation.dart

### Community 85 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.53
Nodes (6): @freezed, CustomerBasket, CustomerBasketSupabaseExtension, OrderSupabaseExtension, Order, User

### Community 86 - "payment_form_dialog.dart"
Cohesion: 0.22
Nodes (8): build, _buildInfoChip, _buildStatusChip, _getDeliveryTypeIcon, _getSaleTypeIcon, getStatusColor, order, OrderCard

### Community 87 - "Requerimientos Funcionales"
Cohesion: 0.20
Nodes (10): 11.1 Funcionamiento Sin Internet, 11.2 Sincronización, 11. Arquitectura Offline-First, 13.1 WhatsApp, 13.2 Mapas, 13.3 Impresora Térmica Bluetooth, 13. Integraciones, 14. Módulos Futuros (Nice-to-Have) (+2 more)

### Community 88 - "3. Módulo de Pedidos y Ventas"
Cohesion: 0.22
Nodes (9): 3.1 Registro de Pedidos, 3.2 Estados del Pedido, 3.3 Facturación e Impresión, 3.4 Cotizaciones, 3.5 Edición de Pedidos, 3.6 Cancelación de Pedidos, 3.7 Entregas Parciales y Pendientes, 3.8 Sistema de Recordatorios de Pedidos (+1 more)

### Community 89 - "add_remove_button.dart"
Cohesion: 0.40
Nodes (4): ../../../../../domain/models/order_item.dart, OrderItemPriceType, OrderItemPriceTypeX, OrderItemPriceTypeStyle

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
Cohesion: 0.15
Nodes (18): ConsumerState, ConsumerStatefulWidget, geocodingContextProvider, geocodingServiceProvider, _geocode, GeocodeCustomerAddressButton, _GeocodeCustomerAddressButtonState, DeliveryOrderDetailView (+10 more)

### Community 96 - "package:go_router/go_router.dart"
Cohesion: 0.25
Nodes (7): ../../../../data/providers/settings_providers.dart, build, _editGeocodingContext, package:go_router/go_router.dart, Route /settings/brands, Route /settings/categories, Route /settings/printer

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

### Community 105 - "order_repository.dart"
Cohesion: 0.11
Nodes (17): ../../domain/models/order_extensions.dart, assignDeliveryPerson, cancel, _client, create, delete, editItem, getAll (+9 more)

### Community 106 - "delivery_view.dart"
Cohesion: 0.15
Nodes (16): ../../../../../data/providers/delivery_providers.dart, deliveryOrdersProvider, DeliveryViewMode, orderZoneGrouperProvider, build, _buildContent, _buildFilterBar, _buildFilterChip (+8 more)

### Community 107 - "location_service.dart"
Cohesion: 0.12
Nodes (16): Exception, captureCurrentPosition, checkPermission, code, _dataSource, GeolocatorDataSource, getCurrentPosition, isLocationServiceEnabled (+8 more)

### Community 108 - "delivery_order_detail_view.dart"
Cohesion: 0.12
Nodes (15): _buildBottomBar, _buildCustomerInfo, _buildItemCard, _buildNotes, _buildOrderHeader, _buildProductsHeader, _buildStatusChip, _canDeliver (+7 more)

### Community 109 - "signature_pad.dart"
Cohesion: 0.13
Nodes (15): CustomPainter, dart:ui, double?, build, clear, createState, exportPng, height (+7 more)

### Community 110 - "delivery_order_card.dart"
Cohesion: 0.11
Nodes (18): ../../../../../domain/services/route_optimizer.dart, currentUserProvider, build, _buildActionChip, _buildActions, _buildBody, _buildHeader, _buildStatusChip (+10 more)

### Community 111 - "delivery_zone_group_card.dart"
Cohesion: 0.14
Nodes (13): delivery_order_card.dart, ../../../../../domain/services/order_zone_grouper.dart, OrderZone, build, currentPosition, onComplete, zone, accentColor (+5 more)

### Community 112 - "Notas Técnicas - Applicoresestacion"
Cohesion: 0.14
Nodes (13): Arquitectura, Configuración, Dependencias, Escáner de Código de Barras, Estructura del Proyecto, Geocoding, Layout de Formularios, mobile_scanner (+5 more)

### Community 113 - "ordersProvider"
Cohesion: 0.50
Nodes (4): customerRepositoryProvider, CustomerFormView, _CustomerFormViewState, _loadCustomer

### Community 114 - "order_zone_grouper.dart"
Cohesion: 0.14
Nodes (13): distanceMeters, group, orderCount, orders, OrderZoneGrouper, OrderZoneResult, radiusMeters, referenceAddress (+5 more)

### Community 115 - "supabase_health_check_view.dart"
Cohesion: 0.18
Nodes (10): ../../../../data/services/supabase_health_check_service.dart, build, _buildResultCard, _buildResults, createState, initState, _isLoading, _results (+2 more)

### Community 116 - "order_filter_bar.dart"
Cohesion: 0.12
Nodes (19): ../../../../../core/responsive.dart, ordersProvider, _saveOrder, _assignDeliveryPerson, _cancelOrder, _buildBody, build, _buildDeliveryTypeDropdown (+11 more)

### Community 117 - "order.dart"
Cohesion: 0.19
Nodes (12): dbValue, DeliveryType, _deliveryTypeFromDb, DeliveryTypeX, fromJson, OrderStatus, _orderStatusFromDb, OrderStatusX (+4 more)

### Community 118 - "normalizar-stock-y-cantidades.sql"
Cohesion: 0.21
Nodes (8): private.cancel_order(), private.edit_order_item(), private.update_product_stock(), public.inventory_movements, public.order_items, public.product_lots, public.products, public.supplier_invoice_items

### Community 119 - "delivery_evidence_service.dart"
Cohesion: 0.18
Nodes (10): dart:typed_data, _bucket, _client, DeliveryEvidenceService, _uploadBinary, uploadPhoto, uploadSignature, _uuid (+2 more)

### Community 120 - "settings_providers.dart"
Cohesion: 0.18
Nodes (10): defaultContext, _load, locationServiceProvider, _prefsKey, resetToDefault, setContext, LocationService, package:shared_preferences/shared_preferences.dart (+2 more)

### Community 121 - "delivery_items_dialog.dart"
Cohesion: 0.20
Nodes (10): OrderItemListExtension, build, createState, _deliveredQuantities, DeliveryItemsDialog, _DeliveryItemsDialogState, initState, items (+2 more)

### Community 122 - "categoriesProvider"
Cohesion: 0.27
Nodes (9): ../../../../data/repositories/category_repository.dart, categoriesProvider, categoryRepositoryProvider, build, build, CategorySettingsView, _showCreateDialog, _slugify (+1 more)

### Community 123 - "customer.dart"
Cohesion: 0.28
Nodes (8): CustomerStatus, _customerStatusFromDb, CustomerStatusX, CustomerType, _customerTypeFromDb, CustomerTypeX, dbValue, fromJson

### Community 124 - "product.dart"
Cohesion: 0.24
Nodes (9): fromJson, PackagingType, _packagingTypeFromDb, packagingTypeToDb, Product, ProductStatus, _productStatusFromDb, ProductSupabaseExtension (+1 more)

### Community 125 - "fix-fractional-quantities.sql"
Cohesion: 0.22
Nodes (5): private.update_product_stock(), public.inventory_movements, public.product_lots, public.products, public.supplier_invoice_items

### Community 126 - "Sistema de Gestión para Licorería"
Cohesion: 0.20
Nodes (10): Características, Comandos Útiles, Documentación, Estructura del Proyecto, Licencia, Requisitos, Roles y Permisos, Sistema de Gestión para Licorería (+2 more)

### Community 127 - "@freezed"
Cohesion: 0.50
Nodes (4): customer.dart, Customer, CustomerSupabaseExtension, toSupabaseJson

### Community 128 - "geocode_customer_address_button.dart"
Cohesion: 0.22
Nodes (8): class, addressController, build, createState, _isLoading, latitudeController, longitudeController, _showSnack

### Community 129 - "route_optimizer.dart"
Cohesion: 0.22
Nodes (8): dart:math, _distanceMeters, distanceToOrder, RouteOptimizer, sortByDistance, _toRadians, ../models/order.dart, package:geolocator/geolocator.dart

### Community 130 - "order_extensions.dart"
Cohesion: 0.20
Nodes (9): double get, OrderItemSupabaseExtension, toRpcJson, toSupabaseJson, totalDiscount, totalQuantity, totalSubtotal, order.dart (+1 more)

### Community 131 - "Arquitectura del Proyecto"
Cohesion: 0.22
Nodes (9): Arquitectura del Proyecto, ✅ Configuración Base, Convenciones de Código, Dependencias Principales, 🚧 En Desarrollo, Estructura de Carpetas, Estructura de un Feature Completo, Features Implementadas (+1 more)

### Community 132 - "Funciones Útiles"
Cohesion: 0.22
Nodes (9): Cancelar Pedido Completo, Crear Pedido Completo (con transacción), Crear Recordatorio Automático, Editar Item de Pedido, Funciones Útiles, Marcar Items como Entregados (Entregas Parciales), Obtener Recordatorios Pendientes, Obtener Resumen de Pedidos Pendientes (+1 more)

### Community 133 - "window_size_service.dart"
Cohesion: 0.12
Nodes (14): getLastSize, initialize, _instance, saveSize, getLastSize, initialize, saveSize, WindowSizeServiceImpl (+6 more)

### Community 134 - "window_size_service_stub.dart"
Cohesion: 0.50
Nodes (4): productRepositoryProvider, _loadProduct, ProductFormView, _ProductFormViewState

### Community 135 - "Sistema de Gestión para Licorería - Documentación Completa"
Cohesion: 0.25
Nodes (6): Licencia, Recursos, Resumen Ejecutivo, Sistema de Gestión para Licorería - Documentación Completa, Stack Tecnológico, Índice

### Community 137 - "Configuración Inicial en Supabase"
Cohesion: 0.29
Nodes (7): 1. Crear Proyecto, 2. Ejecutar el Schema, 3. Configurar Autenticación, 4. Crear Usuarios de Prueba, 5. Importar Productos desde Excel, Base de Datos, Configuración Inicial en Supabase

### Community 138 - "Instalación"
Cohesion: 0.29
Nodes (7): 1. Clonar el repositorio, 2. Configurar Supabase, 3. Instalar dependencias, 4. Generar código (Freezed, JSON Serializable), 5. Crear usuarios de prueba, 6. Ejecutar la aplicación, Instalación

### Community 139 - "json_helpers.dart"
Cohesion: 0.40
Nodes (5): json_helpers.dart, BasketStatus, _basketStatusFromDb, BasketStatusX, fromJson

### Community 140 - "Próximos Pasos"
Cohesion: 0.40
Nodes (5): Corto Plazo, Inmediatos, Largo Plazo, Mediano Plazo, Próximos Pasos

## Knowledge Gaps
- **1085 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `XCTest`, `AppConfig`, `appName` (+1080 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Customer` connect `@freezed` to `customer.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `currentOrderCartProvider`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Why does `build` connect `productsProvider` to `categoriesProvider`, `@freezed`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `$schema`, `.opencode/plugins/graphify.js`, `XCTest` to the rest of the system?**
  _1085 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.06271186440677966 - nodes in this community are weakly interconnected._
- **Should `order_create_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `order_repository.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.1038961038961039 - nodes in this community are weakly interconnected._
- **Should `order_detail_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.049682875264270614 - nodes in this community are weakly interconnected._