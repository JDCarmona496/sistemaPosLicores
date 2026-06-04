import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/features/auth/views/login_view.dart';
import '../ui/features/dashboard/views/dashboard_view.dart';
import '../ui/features/orders/views/orders_view.dart';
import '../ui/features/products/views/products_view.dart';
import '../ui/features/customers/views/customers_view.dart';
import '../ui/features/delivery/views/delivery_view.dart';
import '../ui/features/reports/views/reports_view.dart';
import '../ui/features/settings/views/settings_view.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
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
  ],
);
