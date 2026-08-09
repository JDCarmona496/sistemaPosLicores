import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/reports/report_models.dart';

/// Repositorio de reportes. Usa funciones RPC en Supabase para obtener
/// agregaciones de ventas, productos y métodos de pago.
class ReportsRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  Future<SalesSummary> getSalesSummary({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? sellerId,
  }) async {
    final result = await _client.rpc(
      'get_sales_summary',
      params: {
        'p_date_from': _dateFormat.format(dateFrom),
        'p_date_to': _dateFormat.format(dateTo),
        'p_seller_id': sellerId,
      },
    );

    final data = (result as List<dynamic>?)?.firstOrNull as Map<String, dynamic>?;
    if (data == null) {
      return const SalesSummary(
        totalSales: 0,
        totalOrders: 0,
        averageTicket: 0,
        totalDiscounts: 0,
        totalDeliveryFees: 0,
      );
    }
    return SalesSummary.fromJson(data);
  }

  Future<List<SalesByPaymentMethod>> getSalesByPaymentMethod({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? sellerId,
  }) async {
    final result = await _client.rpc(
      'get_sales_by_payment_method',
      params: {
        'p_date_from': _dateFormat.format(dateFrom),
        'p_date_to': _dateFormat.format(dateTo),
        'p_seller_id': sellerId,
      },
    );

    final data = result as List<dynamic>? ?? [];
    return data
        .map((row) => SalesByPaymentMethod.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopProductReport>> getTopProducts({
    required DateTime dateFrom,
    required DateTime dateTo,
    int limit = 10,
    String? sellerId,
  }) async {
    final result = await _client.rpc(
      'get_top_products',
      params: {
        'p_date_from': _dateFormat.format(dateFrom),
        'p_date_to': _dateFormat.format(dateTo),
        'p_limit': limit,
        'p_seller_id': sellerId,
      },
    );

    final data = result as List<dynamic>? ?? [];
    return data
        .map((row) => TopProductReport.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PendingOrdersSummary> getPendingOrdersSummary({String? sellerId}) async {
    final result = await _client.rpc(
      'get_pending_orders_summary',
      params: {'p_seller_id': sellerId},
    );

    final data = (result as List<dynamic>?)?.firstOrNull as Map<String, dynamic>?;
    if (data == null) {
      return const PendingOrdersSummary(pendingCount: 0, pendingTotal: 0);
    }
    return PendingOrdersSummary.fromJson(data);
  }

  Future<List<SalesBySeller>> getSalesBySeller({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? sellerId,
  }) async {
    final result = await _client.rpc(
      'get_sales_by_seller',
      params: {
        'p_date_from': _dateFormat.format(dateFrom),
        'p_date_to': _dateFormat.format(dateTo),
        'p_seller_id': sellerId,
      },
    );

    final data = result as List<dynamic>? ?? [];
    return data
        .map((row) => SalesBySeller.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<HourlySales>> getHourlySales({
    required DateTime date,
    String? sellerId,
  }) async {
    final result = await _client.rpc(
      'get_hourly_sales',
      params: {
        'p_date': _dateFormat.format(date),
        'p_seller_id': sellerId,
      },
    );

    final data = result as List<dynamic>? ?? [];
    return data
        .map((row) => HourlySales.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SalesTrendPoint>> getSalesTrend({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? sellerId,
  }) async {
    final result = await _client.rpc(
      'get_sales_trend',
      params: {
        'p_date_from': _dateFormat.format(dateFrom),
        'p_date_to': _dateFormat.format(dateTo),
        'p_seller_id': sellerId,
      },
    );

    final data = result as List<dynamic>? ?? [];
    return data
        .map((row) => SalesTrendPoint.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
