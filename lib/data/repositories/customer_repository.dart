import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/customer_extensions.dart';

class CustomerRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Customer>> getAll({
    String? search,
    CustomerType? type,
    CustomerStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('customers').select();

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'full_name.ilike.%$search%,identification.ilike.%$search%,phone.ilike.%$search%',
      );
    }

    if (type != null) {
      query = query.eq('customer_type', type.dbValue);
    }

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final data = await query
        .order('full_name')
        .range(offset, offset + limit - 1);

    return data.map((json) => Customer.fromJson(json)).toList();
  }

  Future<Customer?> getById(String id) async {
    try {
      final data = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Customer?> getByIdentification(String identification) async {
    try {
      final data = await _client
          .from('customers')
          .select()
          .eq('identification', identification)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Customer?> getByPhone(String phone) async {
    try {
      final data = await _client
          .from('customers')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Customer> create(Customer customer) async {
    final data = customer.toSupabaseJson()..remove('id');

    try {
      final result = await _client
          .from('customers')
          .insert(data)
          .select()
          .single();

      return Customer.fromJson(result);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'crear el cliente');
    } catch (e) {
      throw Exception('Error inesperado al crear el cliente: $e');
    }
  }

  Future<Customer> update(Customer customer) async {
    final data = customer.toSupabaseJson();

    try {
      final result = await _client
          .from('customers')
          .update(data)
          .eq('id', customer.id)
          .select()
          .single();

      return Customer.fromJson(result);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'actualizar el cliente');
    } catch (e) {
      throw Exception('Error inesperado al actualizar el cliente: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'eliminar el cliente');
    } catch (e) {
      throw Exception('Error inesperado al eliminar el cliente: $e');
    }
  }

  Future<void> updateBalance(String customerId, double newBalance) async {
    try {
      await _client
          .from('customers')
          .update({'current_balance': newBalance})
          .eq('id', customerId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'actualizar el saldo');
    } catch (e) {
      throw Exception('Error inesperado al actualizar el saldo: $e');
    }
  }

  Future<void> updateStatus(String customerId, CustomerStatus status) async {
    try {
      await _client
          .from('customers')
          .update({'status': status.dbValue})
          .eq('id', customerId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cambiar el estado');
    } catch (e) {
      throw Exception('Error inesperado al cambiar el estado: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersHistory(
    String customerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _client
          .from('orders')
          .select('id, order_number, status, sale_type, total, created_at')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final orders = await _client
          .from('orders')
          .select('id, total, status, sale_type')
          .eq('customer_id', customerId);

      final completedOrders = orders
          .where((o) =>
              o['status'] == 'delivered' || o['status'] == 'completed')
          .toList();

      final totalSpent = completedOrders.fold<double>(
        0,
        (sum, o) => sum + (o['total'] as num).toDouble(),
      );

      final creditOrders = orders
          .where((o) => o['sale_type'] == 'credit')
          .toList();

      return {
        'total_orders': orders.length,
        'completed_orders': completedOrders.length,
        'total_spent': totalSpent,
        'credit_orders': creditOrders.length,
      };
    } catch (e) {
      return {
        'total_orders': 0,
        'completed_orders': 0,
        'total_spent': 0.0,
        'credit_orders': 0,
      };
    }
  }

  Exception _handlePostgrestError(PostgrestException e, String action) {
    final message = e.message.toLowerCase();

    if (message.contains('unique') || message.contains('duplicate')) {
      return Exception(
          'Ya existe un cliente con esa identificación o teléfono.');
    }
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
