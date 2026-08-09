import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/cash_register.dart';
import '../../domain/models/shift.dart';

class ShiftRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Obtiene el turno abierto para un usuario específico.
  /// Si hay varios, devuelve el más reciente.
  Future<Shift?> getOpenShiftForUser(String userId) async {
    try {
      final data = await _client
          .from('shifts')
          .select()
          .eq('opened_by', userId)
          .eq('status', 'open')
          .order('opened_at', ascending: false)
          .maybeSingle();

      if (data == null) return null;
      return Shift.fromJson(data);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cargar el turno');
    } catch (e) {
      throw Exception('Error inesperado al cargar el turno: $e');
    }
  }

  Future<Shift?> getById(String id) async {
    try {
      final data = await _client
          .from('shifts')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Shift.fromJson(data);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cargar el turno');
    } catch (e) {
      throw Exception('Error inesperado al cargar el turno: $e');
    }
  }

  Future<List<CashRegister>> getActiveCashRegisters() async {
    try {
      final data = await _client
          .from('cash_registers')
          .select()
          .eq('is_active', true)
          .order('name');

      return data.map((json) => CashRegister.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cargar las cajas');
    } catch (e) {
      throw Exception('Error inesperado al cargar las cajas: $e');
    }
  }

  Future<Shift> create(Shift shift) async {
    final data = shift.toSupabaseJson();
    try {
      final result = await _client
          .from('shifts')
          .insert(data)
          .select()
          .single();

      return Shift.fromJson(result);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'abrir el turno');
    } catch (e) {
      throw Exception('Error inesperado al abrir el turno: $e');
    }
  }

  /// Cierra un turno calculando el monto esperado y la diferencia.
  Future<Shift> closeShift({
    required String shiftId,
    required double closingAmount,
    String? notes,
  }) async {
    try {
      final shiftData = await _client
          .from('shifts')
          .select('opening_amount')
          .eq('id', shiftId)
          .single();

      final openingAmount = (shiftData['opening_amount'] as num).toDouble();
      final transactionsSum = await _getTransactionsSum(shiftId);
      final expectedAmount = openingAmount + transactionsSum;
      final difference = closingAmount - expectedAmount;

      final updateData = {
        'status': 'closed',
        'closing_amount': closingAmount,
        'expected_amount': expectedAmount,
        'difference': difference,
        'closed_at': DateTime.now().toUtc().toIso8601String(),
        'closed_by': _client.auth.currentUser?.id,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      debugPrint('[ShiftRepository] Cerrando turno $shiftId con datos: $updateData');

      await _client.from('shifts').update(updateData).eq('id', shiftId);

      final updated = await getById(shiftId);
      if (updated == null) {
        throw Exception('No se pudo verificar el cierre del turno');
      }
      if (updated.status != ShiftStatus.closed) {
        throw Exception('El turno no pudo cerrarse (verifica permisos RLS)');
      }

      return updated;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cerrar el turno');
    } catch (e) {
      throw Exception('Error inesperado al cerrar el turno: $e');
    }
  }

  /// Calcula el monto esperado de un turno (apertura + transacciones).
  Future<double> getExpectedAmount(Shift shift) async {
    final transactionsSum = await _getTransactionsSum(shift.id);
    return shift.openingAmount + transactionsSum;
  }

  /// Suma ingresos - egresos de cash_transactions para el turno.
  Future<double> _getTransactionsSum(String shiftId) async {
    try {
      final data = await _client
          .from('cash_transactions')
          .select('transaction_type, amount')
          .eq('shift_id', shiftId);

      return data.fold<double>(0, (sum, row) {
        final amount = (row['amount'] as num).toDouble();
        final type = row['transaction_type'] as String?;
        return sum + (type == 'expense' ? -amount : amount);
      });
    } catch (e) {
      return 0;
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
