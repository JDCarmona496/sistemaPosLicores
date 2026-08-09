import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/cash_count.dart';

class CashCountRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<CashCount>> getByShift(String shiftId) async {
    try {
      final data = await _client
          .from('cash_counts')
          .select('*, cash_count_denominations(*)')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return data.map((json) => CashCount.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cargar los conteos');
    } catch (e) {
      throw Exception('Error inesperado al cargar los conteos: $e');
    }
  }

  Future<CashCount?> getById(String id) async {
    try {
      final data = await _client
          .from('cash_counts')
          .select('*, cash_count_denominations(*)')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return CashCount.fromJson(data);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cargar el conteo');
    } catch (e) {
      throw Exception('Error inesperado al cargar el conteo: $e');
    }
  }

  Future<CashCount> create(CashCount cashCount) async {
    final parentData = cashCount.toSupabaseJson();

    try {
      final parentResult = await _client
          .from('cash_counts')
          .insert(parentData)
          .select()
          .single();

      final createdId = parentResult['id'] as String;

      final detailData = cashCount.denominations
          .where((d) => d.quantity > 0)
          .map((d) => d.toSupabaseJson()..['cash_count_id'] = createdId)
          .toList();

      if (detailData.isNotEmpty) {
        await _client.from('cash_count_denominations').insert(detailData);
      }

      return CashCount.fromJson({
        ...parentResult,
        'cash_count_denominations': detailData,
      });
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'guardar el conteo');
    } catch (e) {
      throw Exception('Error inesperado al guardar el conteo: $e');
    }
  }

  Exception _handlePostgrestError(PostgrestException e, String action) {
    final message = e.message.toLowerCase();

    if (message.contains('foreign key') || message.contains('violates foreign')) {
      return Exception(
          'No se puede $action porque hay registros relacionados.');
    }
    if (message.contains('permission denied') || message.contains('rls')) {
      return Exception(
          'No tienes permisos para $action. Contacta al administrador.');
    }

    return Exception('Error al $action: ${e.message}');
  }
}
