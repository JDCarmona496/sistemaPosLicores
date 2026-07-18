# Graph Report - .  (2026-07-17)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1154 nodes · 1580 edges · 85 communities (78 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7c794e90`
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
- window_size_service.dart
- window_size_service_stub.dart
- package:supabase_flutter/supabase_flutter.dart
- StateNotifier
- PrinterService
- package:flutter_riverpod/flutter_riverpod.dart
- json_helpers.dart
- user.dart
- package:freezed_annotation/freezed_annotation.dart
- MainActivity
- graphify.js
- bluetooth_printer_service_io.dart
- serial_printer_service.dart
- windows_printer_service.dart
- @licoreria
- String?

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `productsProvider` - 14 edges
3. `currentOrderCartProvider` - 12 edges
4. `MessageHandler` - 12 edges
5. `customersProvider` - 10 edges
6. `ordersProvider` - 10 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `_CustomerDetailViewState` - 9 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `_CustomerFormViewState` --references--> `customersProvider`  [EXTRACTED]
  lib/ui/features/customers/views/customer_form_view.dart → lib/data/providers/customer_providers.dart
- `_save` --references--> `customersProvider`  [EXTRACTED]
  lib/ui/features/customers/views/customer_form_view.dart → lib/data/providers/customer_providers.dart
- `_buildCustomersList` --references--> `customersProvider`  [EXTRACTED]
  lib/ui/features/customers/views/customers_view.dart → lib/data/providers/customer_providers.dart

## Import Cycles
- None detected.

## Communities (85 total, 7 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.06
Nodes (52): FlutterViewController, Point, RECT, Size, unique_ptr, DartProject, HWND, LPARAM (+44 more)

### Community 1 - "order_providers.dart"
Cohesion: 0.04
Nodes (51): addItem, assignDeliveryPerson, cancelOrder, clearCart, clearFilters, copyWith, createOrder, customerAddress (+43 more)

### Community 2 - "order_create_view.dart"
Cohesion: 0.05
Nodes (39): _, class, ../../../../core/responsive.dart, IconData, _addressController, _buildBottomBar, _buildCartItem, _buildCartPanel (+31 more)

### Community 3 - "order_repository.dart"
Cohesion: 0.06
Nodes (35): ../../domain/models/order.dart, ../../domain/models/order_extensions.dart, ../../domain/models/order_item.dart, ReceiptGenerator, assignDeliveryPerson, cancel, _client, create (+27 more)

### Community 4 - "order_detail_view.dart"
Cohesion: 0.06
Nodes (35): ../../../../data/providers/payment_providers.dart, ../../../../data/providers/user_providers.dart, _amountController, _buildBottomBar, _buildCustomerInfo, _buildInfoChip, _buildItemCard, _buildMenuItems (+27 more)

### Community 5 - "customer_form_view.dart"
Cohesion: 0.07
Nodes (31): FormState, customerRepositoryProvider, _addressController, build, _buildSection, createState, _creditLimitController, _currentBalanceController (+23 more)

### Community 6 - "product_form_view.dart"
Cohesion: 0.06
Nodes (31): _barcodeController, _buildSectionTitle, _codeController, _costController, createState, _descriptionController, dispose, _formKey (+23 more)

### Community 7 - "product_providers.dart"
Cohesion: 0.07
Nodes (27): ../../data/repositories/product_repository.dart, brandRepositoryProvider, categoryRepositoryProvider, clearFilters, copyWith, createProduct, deleteProduct, error (+19 more)

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
Cohesion: 0.11
Nodes (21): ../../../../data/providers/order_providers.dart, ordersProvider, _saveOrder, _assignDeliveryPerson, _cancelOrder, build, _buildFilters, _buildInfoChip (+13 more)

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
Cohesion: 0.15
Nodes (18): brandsProvider, categoriesProvider, productsProvider, _buildCatalogPanel, _onCategorySelected, _showDeleteDialog, build, _generateNextCode (+10 more)

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
Cohesion: 0.14
Nodes (14): ../../../../data/services/supabase_health_check_service.dart, OrderItemListExtension, build, _buildResultCard, _buildResults, createState, initState, _isLoading (+6 more)

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
Cohesion: 0.18
Nodes (13): OrderItemSupabaseExtension, dbValue, fromJson, isColdPrice, isFullyDelivered, isWholesalePrice, OrderItem, OrderItemExtension (+5 more)

### Community 28 - "package:go_router/go_router.dart"
Cohesion: 0.15
Nodes (12): BarcodeScannerView, _BarcodeScannerViewState, build, _controller, createState, dispose, _hasScanned, build (+4 more)

### Community 29 - "window_size_service_web.dart"
Cohesion: 0.15
Nodes (12): dart:html, dart:math, _debounce, getLastSize, _heightKey, initialize, _onResize, saveSize (+4 more)

### Community 30 - "product_detail_view.dart"
Cohesion: 0.17
Nodes (12): ../../domain/models/product.dart, productByIdProvider, build, _buildChip, _buildFeatureRow, _buildMarginInfo, _buildPriceRow, _buildProductDetail (+4 more)

### Community 31 - "package:flutter/material.dart"
Cohesion: 0.17
Nodes (11): ResponsiveBuilder, ResponsiveVisibility, LicoreriaApp, build, DeliveryView, _IconButton, build, ReportsView (+3 more)

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
Cohesion: 0.17
Nodes (11): ../../../../data/providers/customer_providers.dart, ../../domain/models/customer.dart, _buildCustomerCard, _buildInfoChip, _buildStatusBadge, createState, dispose, _getTypeColor (+3 more)

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
Cohesion: 0.17
Nodes (11): connect, disconnect, discoverDevices, isConnected, printBytes, printPdf, _selectedPrinter, supportsPdf (+3 more)

### Community 40 - "order.dart"
Cohesion: 0.21
Nodes (11): dbValue, DeliveryType, _deliveryTypeFromDb, DeliveryTypeX, fromJson, OrderStatus, _orderStatusFromDb, OrderStatusX (+3 more)

### Community 41 - "_OrderDetailViewState"
Cohesion: 0.24
Nodes (11): ConsumerWidget, orderByIdProvider, orderItemsProvider, paymentsByOrderProvider, printOrderReceiptProvider, deliveryUsersProvider, build, _DeliveryPersonSelectorDialog (+3 more)

### Community 42 - "order_extensions.dart"
Cohesion: 0.20
Nodes (10): double get, OrderSupabaseExtension, toRpcJson, toSupabaseJson, totalDiscount, totalQuantity, totalSubtotal, Order (+2 more)

### Community 43 - "supabase_service.dart"
Cohesion: 0.18
Nodes (10): _client, delete, insert, insertMany, rpc, select, selectOne, subscribe (+2 more)

### Community 44 - "payment.dart"
Cohesion: 0.25
Nodes (10): fromJson, Payment, PaymentMethod, _paymentMethodFromDb, PaymentMethodX, PaymentStatus, _paymentStatusFromDb, PaymentStatusX (+2 more)

### Community 45 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 46 - "@freezed"
Cohesion: 0.27
Nodes (9): @freezed, customer.dart, PrinterConfigNotifier, CustomerBasket, CustomerBasketSupabaseExtension, Customer, CustomerSupabaseExtension, toSupabaseJson (+1 more)

### Community 47 - "ConsumerState"
Cohesion: 0.24
Nodes (10): ConsumerState, ConsumerStatefulWidget, CustomerDetailView, CustomersView, _CustomersViewState, _CustomerSelectorDialog, _CustomerSelectorDialogState, OrderCreateView (+2 more)

### Community 48 - "serial_printer_service_web.dart"
Cohesion: 0.22
Nodes (8): ../../domain/models/printer_config.dart, connect, disconnect, discoverDevices, isConnected, printBytes, printPdf, supportsPdf

### Community 49 - "products_view.dart"
Cohesion: 0.20
Nodes (9): ../../../../data/providers/product_providers.dart, ../../data/repositories/brand_repository.dart, ../../data/repositories/category_repository.dart, _buildProductCard, _buildStockBadge, createState, dispose, _searchController (+1 more)

### Community 50 - "payment_providers.dart"
Cohesion: 0.20
Nodes (9): ../../domain/models/payment.dart, getByCustomer, getByOrder, paymentRepositoryProvider, paymentsByCustomerProvider, repository, PaymentRepository, _registerPayment (+1 more)

### Community 51 - "theme.dart"
Cohesion: 0.20
Nodes (9): AppTheme, backgroundColor, errorColor, primaryColor, secondaryColor, successColor, surfaceColor, warningColor (+1 more)

### Community 52 - "_CustomerDetailViewState"
Cohesion: 0.24
Nodes (10): customerBasketsProvider, customerBasketStatsProvider, customerByIdProvider, customerOrdersHistoryProvider, customerStatsProvider, build, _buildBasketsTab, _buildOrdersTab (+2 more)

### Community 53 - "customer.dart"
Cohesion: 0.24
Nodes (9): CustomerStatus, _customerStatusFromDb, CustomerStatusX, CustomerType, _customerTypeFromDb, CustomerTypeX, dbValue, fromJson (+1 more)

### Community 54 - "product.dart"
Cohesion: 0.24
Nodes (9): fromJson, PackagingType, _packagingTypeFromDb, packagingTypeToDb, Product, ProductStatus, _productStatusFromDb, ProductSupabaseExtension (+1 more)

### Community 55 - "State"
Cohesion: 0.27
Nodes (10): LoginView, _LoginViewState, DashboardView, _DashboardViewState, _DeliveryItemsDialog, _DeliveryItemsDialogState, _PaymentDialog, _PaymentDialogState (+2 more)

### Community 56 - "main.dart"
Cohesion: 0.22
Nodes (8): config/router.dart, config/theme.dart, data/services/window_size/window_size_service.dart, build, initialize, main, _waitForInitialSession, package:flutter/foundation.dart

### Community 57 - "auth_service.dart"
Cohesion: 0.22
Nodes (8): AuthService, authStateChanges, _client, getCurrentUser, signIn, signOut, Stream, SupabaseClient get

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
Cohesion: 0.25
Nodes (8): currentOrderCartProvider, _buildCustomerSection, _buildNotesSection, _onProductDecrement, _onProductIncrement, _quantityInCart, _selectCustomer, _totalQuantityInCart

### Community 63 - "config/supabase_config.dart"
Cohesion: 0.25
Nodes (7): config/supabase_config.dart, _client, create, delete, getByCustomer, getByOrder, _handleError

### Community 64 - "window_size_service.dart"
Cohesion: 0.25
Nodes (7): getLastSize, initialize, _instance, saveSize, static final WindowSizeService, static WindowSizeService get, window_size_service_stub.dart

### Community 65 - "window_size_service_stub.dart"
Cohesion: 0.25
Nodes (7): getLastSize, initialize, saveSize, WindowSizeServiceImpl, WindowSizeServiceImpl, WindowSizeService, window_size_service.dart

### Community 66 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.29
Nodes (6): app_config.dart, client, initialize, SupabaseConfig, package:supabase_flutter/supabase_flutter.dart, static SupabaseClient get

### Community 67 - "StateNotifier"
Cohesion: 0.29
Nodes (7): CustomersNotifier, CustomersState, CurrentOrderCartNotifier, CurrentOrderCartState, OrdersNotifier, OrdersState, StateNotifier

### Community 68 - "PrinterService"
Cohesion: 0.29
Nodes (7): BluetoothPrinterService, BluetoothPrinterService, PrinterService, SerialPrinterService, SerialPrinterService, WindowsPrinterService, WindowsPrinterService

### Community 69 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.33
Nodes (5): ../../domain/models/user.dart, client, data, map, package:flutter_riverpod/flutter_riverpod.dart

### Community 70 - "json_helpers.dart"
Cohesion: 0.40
Nodes (5): json_helpers.dart, BasketStatus, _basketStatusFromDb, BasketStatusX, fromJson

### Community 71 - "user.dart"
Cohesion: 0.47
Nodes (5): fromJson, User, UserRole, _userRoleFromDb, UserRoleX

### Community 72 - "package:freezed_annotation/freezed_annotation.dart"
Cohesion: 0.50
Nodes (4): fromJson, PrinterConnectionType, PrinterConnectionTypeX, package:freezed_annotation/freezed_annotation.dart

## Knowledge Gaps
- **659 isolated node(s):** `XCTest`, `AppConfig`, `appName`, `appVersion`, `supabaseUrl` (+654 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CustomerType` connect `customer.dart` to `customer_providers.dart`, `order_providers.dart`, `customer_form_view.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `PaymentMethod` connect `payment.dart` to `order_detail_view.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `Customer` connect `@freezed` to `order_create_view.dart`, `customer.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **What connects `XCTest`, `AppConfig`, `appName` to the rest of the system?**
  _659 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.06271186440677966 - nodes in this community are weakly interconnected._
- **Should `order_providers.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
- **Should `order_create_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._