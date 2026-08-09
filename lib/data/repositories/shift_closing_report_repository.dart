import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/reports/shift_closing_report.dart';

/// Repositorio para el reporte de cierre de caja por turno.
class ShiftClosingReportRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  Future<List<ShiftClosingReport>> getByDate({
    required DateTime date,
    String? userId,
  }) async {
    final result = await _client.rpc(
      'get_shift_closing_report',
      params: {
        'p_date': _dateFormat.format(date),
        'p_user_id': userId,
      },
    );

    final data = result as List<dynamic>? ?? [];
    return data
        .map((row) => ShiftClosingReport.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
