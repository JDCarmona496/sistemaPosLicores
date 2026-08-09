import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/reports/report_models.dart';
import '../../domain/models/user.dart';
import '../services/auth_service.dart';
import '../repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final repository = ref.watch(reportsRepositoryProvider);
  return ReportsNotifier(repository);
});

/// Rango de fechas por defecto: últimos 7 días.
DateTime _defaultDateFrom() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
}

DateTime _defaultDateTo() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class ReportsState {
  final DateTime dateFrom;
  final DateTime dateTo;
  final bool isLoading;
  final String? error;
  final SalesSummary salesSummary;
  final PendingOrdersSummary pendingOrders;
  final List<SalesTrendPoint> salesTrend;
  final List<SalesByPaymentMethod> salesByPayment;
  final List<TopProductReport> topProducts;
  final List<HourlySales> hourlySales;
  final List<SalesBySeller> salesBySeller;

  const ReportsState({
    required this.dateFrom,
    required this.dateTo,
    this.isLoading = false,
    this.error,
    this.salesSummary = const SalesSummary(
      totalSales: 0,
      totalOrders: 0,
      averageTicket: 0,
      totalDiscounts: 0,
      totalDeliveryFees: 0,
    ),
    this.pendingOrders = const PendingOrdersSummary(
      pendingCount: 0,
      pendingTotal: 0,
    ),
    this.salesTrend = const [],
    this.salesByPayment = const [],
    this.topProducts = const [],
    this.hourlySales = const [],
    this.salesBySeller = const [],
  });

  ReportsState copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isLoading,
    String? error,
    SalesSummary? salesSummary,
    PendingOrdersSummary? pendingOrders,
    List<SalesTrendPoint>? salesTrend,
    List<SalesByPaymentMethod>? salesByPayment,
    List<TopProductReport>? topProducts,
    List<HourlySales>? hourlySales,
    List<SalesBySeller>? salesBySeller,
    bool clearError = false,
  }) {
    return ReportsState(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      salesSummary: salesSummary ?? this.salesSummary,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      salesTrend: salesTrend ?? this.salesTrend,
      salesByPayment: salesByPayment ?? this.salesByPayment,
      topProducts: topProducts ?? this.topProducts,
      hourlySales: hourlySales ?? this.hourlySales,
      salesBySeller: salesBySeller ?? this.salesBySeller,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository _repository;

  ReportsNotifier(this._repository)
      : super(ReportsState(
          dateFrom: _defaultDateFrom(),
          dateTo: _defaultDateTo(),
        )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await AuthService().getCurrentUser();
      final sellerId = user.role == UserRole.admin ? null : user.id;

      final results = await Future.wait([
        _repository.getSalesSummary(
          dateFrom: state.dateFrom,
          dateTo: state.dateTo,
          sellerId: sellerId,
        ),
        _repository.getPendingOrdersSummary(sellerId: sellerId),
        _repository.getSalesTrend(
          dateFrom: state.dateFrom,
          dateTo: state.dateTo,
          sellerId: sellerId,
        ),
        _repository.getSalesByPaymentMethod(
          dateFrom: state.dateFrom,
          dateTo: state.dateTo,
          sellerId: sellerId,
        ),
        _repository.getTopProducts(
          dateFrom: state.dateFrom,
          dateTo: state.dateTo,
          limit: 10,
          sellerId: sellerId,
        ),
        _repository.getHourlySales(
          date: state.dateTo,
          sellerId: sellerId,
        ),
        _repository.getSalesBySeller(
          dateFrom: state.dateFrom,
          dateTo: state.dateTo,
          sellerId: sellerId,
        ),
      ]);

      state = state.copyWith(
        isLoading: false,
        salesSummary: results[0] as SalesSummary,
        pendingOrders: results[1] as PendingOrdersSummary,
        salesTrend: results[2] as List<SalesTrendPoint>,
        salesByPayment: results[3] as List<SalesByPaymentMethod>,
        topProducts: results[4] as List<TopProductReport>,
        hourlySales: results[5] as List<HourlySales>,
        salesBySeller: results[6] as List<SalesBySeller>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar reportes: ${e.toString()}',
      );
    }
  }

  Future<void> setDateRange(DateTime from, DateTime to) async {
    state = state.copyWith(dateFrom: from, dateTo: to);
    await load();
  }
}
