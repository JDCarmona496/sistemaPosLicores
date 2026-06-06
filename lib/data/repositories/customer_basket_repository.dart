import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/customer_basket.dart';
import '../../domain/models/customer_basket_extensions.dart';

class CustomerBasketRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<CustomerBasket>> getByCustomer(String customerId) async {
    final data = await _client
        .from('customer_baskets')
        .select('*, product:products(name, code)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return data.map((json) {
      final product = json['product'] as Map<String, dynamic>?;
      json['product_name'] = product?['name'];
      json['product_code'] = product?['code'];
      return CustomerBasket.fromJson(json);
    }).toList();
  }

  Future<List<CustomerBasket>> getPendingByCustomer(String customerId) async {
    final data = await _client
        .from('customer_baskets')
        .select('*, product:products(name, code)')
        .eq('customer_id', customerId)
        .eq('status', 'outstanding')
        .order('created_at', ascending: false);

    return data.map((json) {
      final product = json['product'] as Map<String, dynamic>?;
      json['product_name'] = product?['name'];
      json['product_code'] = product?['code'];
      return CustomerBasket.fromJson(json);
    }).toList();
  }

  Future<CustomerBasket> create(CustomerBasket basket) async {
    final data = basket.toSupabaseJson()..remove('id');

    final result = await _client
        .from('customer_baskets')
        .insert(data)
        .select()
        .single();

    return CustomerBasket.fromJson(result);
  }

  Future<CustomerBasket> update(CustomerBasket basket) async {
    final data = basket.toSupabaseJson();

    final result = await _client
        .from('customer_baskets')
        .update(data)
        .eq('id', basket.id)
        .select()
        .single();

    return CustomerBasket.fromJson(result);
  }

  Future<CustomerBasket> returnBaskets({
    required String basketId,
    required int quantityReturned,
  }) async {
    final current = await _client
        .from('customer_baskets')
        .select()
        .eq('id', basketId)
        .single();

    final currentReturned = (current['quantity_returned'] as int?) ?? 0;
    final quantityOut = (current['quantity_out'] as int?) ?? 0;
    final newReturned = currentReturned + quantityReturned;
    final isFullyReturned = newReturned >= quantityOut;

    final updateData = <String, dynamic>{
      'quantity_returned': newReturned,
      'status': isFullyReturned ? 'returned' : 'outstanding',
    };

    if (isFullyReturned) {
      updateData['returned_at'] = DateTime.now().toIso8601String();
    }

    final result = await _client
        .from('customer_baskets')
        .update(updateData)
        .eq('id', basketId)
        .select()
        .single();

    return CustomerBasket.fromJson(result);
  }

  Future<void> delete(String id) async {
    await _client.from('customer_baskets').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> getBasketStats(String customerId) async {
    final data = await _client
        .from('customer_baskets')
        .select('quantity_out, quantity_returned, status, deposit_amount')
        .eq('customer_id', customerId);

    int totalOut = 0;
    int totalReturned = 0;
    int totalPending = 0;
    double totalDeposit = 0;

    for (final row in data) {
      final out = (row['quantity_out'] as int?) ?? 0;
      final returned = (row['quantity_returned'] as int?) ?? 0;
      final deposit = (row['deposit_amount'] as num?)?.toDouble() ?? 0;

      totalOut += out;
      totalReturned += returned;
      totalPending += (out - returned);
      totalDeposit += deposit;
    }

    return {
      'total_out': totalOut,
      'total_returned': totalReturned,
      'total_pending': totalPending,
      'total_deposit': totalDeposit,
    };
  }
}
