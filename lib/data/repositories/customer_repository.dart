import '../../config/supabase_config.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/customer_basket.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Customer>> getAll({
    String? search,
    String? customerType,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('customers').select();

    if (search != null && search.isNotEmpty) {
      query = query.or(
          'full_name.ilike.%$search%,phone.ilike.%$search%,identification.ilike.%$search%');
    }

    if (customerType != null) {
      query = query.eq('customer_type', customerType);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('full_name').range(offset, offset + limit - 1);

    return data.map((json) => Customer.fromJson(json)).toList();
  }

  Future<Customer?> getById(String id) async {
    try {
      final data = await _client.from('customers').select().eq('id', id).maybeSingle();

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
      final data =
          await _client.from('customers').select().eq('phone', phone).maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Customer> create(Customer customer) async {
    final data = customer.toSupabaseJson();

    final result = await _client.from('customers').insert(data).select().single();

    return Customer.fromJson(result);
  }

  Future<Customer> update(Customer customer) async {
    final data = customer.toSupabaseJson();

    final result =
        await _client.from('customers').update(data).eq('id', customer.id).select().single();

    return Customer.fromJson(result);
  }

  Future<void> delete(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId,
      {int limit = 20}) async {
    try {
      final data = await _client
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(limit);

      return data;
    } catch (e) {
      return [];
    }
  }

  Future<List<CustomerBasket>> getCustomerBaskets(String customerId) async {
    try {
      final data = await _client
          .from('customer_baskets')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return data.map((json) => CustomerBasket.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<CustomerBasket> createBasket(CustomerBasket basket) async {
    final data = basket.toSupabaseJson();

    final result =
        await _client.from('customer_baskets').insert(data).select().single();

    return CustomerBasket.fromJson(result);
  }

  Future<CustomerBasket> updateBasket(CustomerBasket basket) async {
    final data = basket.toSupabaseJson();

    final result = await _client
        .from('customer_baskets')
        .update(data)
        .eq('id', basket.id)
        .select()
        .single();

    return CustomerBasket.fromJson(result);
  }

  Future<void> deleteBasket(String id) async {
    await _client.from('customer_baskets').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final orders = await _client
          .from('orders')
          .select('id, total, status')
          .eq('customer_id', customerId);

      final totalOrders = orders.length;
      final totalSpent = orders.fold<double>(
          0, (sum, order) => sum + (order['total'] as num? ?? 0).toDouble());

      final pendingOrders =
          orders.where((o) => o['status'] != 'delivered' && o['status'] != 'cancelled').length;

      return {
        'total_orders': totalOrders,
        'total_spent': totalSpent,
        'pending_orders': pendingOrders,
      };
    } catch (e) {
      return {
        'total_orders': 0,
        'total_spent': 0.0,
        'pending_orders': 0,
      };
    }
  }
}
