import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/features/auth/views/login_view.dart';
import '../ui/features/dashboard/views/dashboard_view.dart';
import '../ui/features/orders/views/orders_view.dart';
import '../ui/features/products/views/products_view.dart';
import '../ui/features/products/views/product_detail_view.dart';
import '../ui/features/products/views/product_form_view.dart';
import '../ui/features/products/views/barcode_scanner_view.dart';
import '../ui/features/customers/views/customers_view.dart';
import '../ui/features/customers/views/customer_detail_view.dart';
import '../ui/features/customers/views/customer_form_view.dart';
import '../ui/features/delivery/views/delivery_view.dart';
import '../ui/features/reports/views/reports_view.dart';
import '../ui/features/settings/views/settings_view.dart';
import '../ui/features/settings/views/supabase_health_check_view.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoginRoute = state.matchedLocation == '/login';
    final isHealthCheckRoute = state.matchedLocation == '/supabase-check';

    if (isHealthCheckRoute) return null;

    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }

    if (isLoggedIn && isLoginRoute) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/dashboard',
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const OrdersView(),
    ),
    GoRoute(
      path: '/products',
      name: 'products',
      builder: (context, state) => const ProductsView(),
      routes: [
        GoRoute(
          path: 'create',
          name: 'product-create',
          builder: (context, state) => const ProductFormView(),
        ),
        GoRoute(
          path: 'edit/:id',
          name: 'product-edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProductFormView(productId: id);
          },
        ),
        GoRoute(
          path: ':id',
          name: 'product-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProductDetailView(productId: id);
          },
        ),
        GoRoute(
          path: 'scan',
          name: 'barcode-scan',
          builder: (context, state) => const BarcodeScannerView(),
        ),
      ],
    ),
    GoRoute(
      path: '/customers',
      name: 'customers',
      builder: (context, state) => const CustomersView(),
    ),
    GoRoute(
      path: '/delivery',
      name: 'delivery',
      builder: (context, state) => const DeliveryView(),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => const ReportsView(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsView(),
    ),
    GoRoute(
      path: '/supabase-check',
      name: 'supabase-check',
      builder: (context, state) => const SupabaseHealthCheckView(),
    ),
  ],
);
