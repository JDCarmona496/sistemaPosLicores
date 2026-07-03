import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/payment.dart';

class PaymentRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Payment>> getByOrder(String orderId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);

    return data.map((json) => Payment.fromJson(json)).toList();
  }

  Future<List<Payment>> getByCustomer(String customerId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return data.map((json) => Payment.fromJson(json)).toList();
  }

  Future<Payment> create({
    String? orderId,
    String? customerId,
    required PaymentMethod paymentMethod,
    required double amount,
    String? reference,
    required String receivedBy,
    String? notes,
  }) async {
    try {
      final data = await _client
          .from('payments')
          .insert({
            'order_id': orderId,
            'customer_id': customerId,
            'payment_method': paymentMethod.name,
            'amount': amount,
            'reference': reference,
            'received_by': receivedBy,
            'notes': notes,
          })
          .select()
          .single();

      return Payment.fromJson(data);
    } on PostgrestException catch (e) {
      throw _handleError(e, 'registrar el pago');
    } catch (e) {
      throw Exception('Error inesperado al registrar el pago: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('payments').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _handleError(e, 'eliminar el pago');
    } catch (e) {
      throw Exception('Error inesperado al eliminar el pago: $e');
    }
  }

  Exception _handleError(PostgrestException e, String action) {
    final message = e.message.toLowerCase();

    if (message.contains('permission denied') || message.contains('rls')) {
      return Exception(
          'No tienes permisos para $action. Contacta al administrador.');
    }

    return Exception('Error al $action: ${e.message}');
  }
}
