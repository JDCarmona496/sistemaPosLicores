import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:applicoresestacion/config/supabase_config.dart';
import 'package:applicoresestacion/domain/models/credit_account.dart';
import 'package:applicoresestacion/domain/models/order.dart';
import 'package:applicoresestacion/domain/models/order_item.dart';
import 'package:applicoresestacion/domain/models/payment.dart';

/// Repositorio para el módulo de créditos.
///
/// Agrupa pedidos de tipo crédito con sus pagos e ítems para mostrar
/// saldos, abonos y estado de entrega pendiente.
class CreditRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Devuelve todos los pedidos a crédito no cancelados, con sus pagos.
  Future<List<CreditAccount>> getCreditAccounts() async {
    final orders = await _getCreditOrders();
    if (orders.isEmpty) return [];

    final orderIds = orders.map((o) => o.id).toList();
    final payments = await _getPaymentsForOrders(orderIds);

    return orders.map((order) {
      final orderPayments =
          payments.where((p) => p.orderId == order.id).toList();
      return CreditAccount(order: order, payments: orderPayments);
    }).toList();
  }

  /// Devuelve un pedido a crédito con sus pagos e ítems.
  Future<CreditAccount?> getCreditAccountByOrderId(String orderId) async {
    final orderData = await _client
        .from('orders')
        .select('''
          id,
          order_number,
          customer_id,
          seller_id,
          delivery_person_id,
          status,
          sale_type,
          delivery_type,
          subtotal,
          discount_amount,
          tax_amount,
          delivery_fee,
          total,
          notes,
          delivery_address,
          delivery_latitude,
          delivery_longitude,
          delivery_photo_url,
          delivery_signature,
          delivered_at,
          cancelled_reason,
          cancelled_by,
          cancelled_at,
          edit_count,
          created_at,
          updated_at,
          customer:customers(id, full_name, phone, address)
        ''')
        .eq('id', orderId)
        .eq('sale_type', SaleType.credit.dbValue)
        .maybeSingle();

    if (orderData == null) return null;

    final customer = orderData['customer'] as Map<String, dynamic>?;
    orderData['customer_name'] = customer?['full_name'];
    orderData['customer_phone'] = customer?['phone'];
    orderData['customer_address'] = customer?['address'];

    final order = Order.fromJson(orderData);
    final payments = await _getPaymentsForOrders([orderId]);
    final items = await _getItemsForOrders([orderId]);

    return CreditAccount(
      order: order,
      payments: payments,
      items: items,
    );
  }

  Future<List<Order>> _getCreditOrders() async {
    final data = await _client
        .from('orders')
        .select('''
          id,
          order_number,
          customer_id,
          seller_id,
          delivery_person_id,
          status,
          sale_type,
          delivery_type,
          subtotal,
          discount_amount,
          tax_amount,
          delivery_fee,
          total,
          notes,
          delivery_address,
          delivery_latitude,
          delivery_longitude,
          created_at,
          updated_at,
          customer:customers(full_name, phone)
        ''')
        .eq('sale_type', SaleType.credit.dbValue)
        .neq('status', OrderStatus.cancelled.dbValue)
        .order('created_at', ascending: false);

    return data.map((json) {
      final customer = json['customer'] as Map<String, dynamic>?;
      json['customer_name'] = customer?['full_name'];
      json['customer_phone'] = customer?['phone'];
      return Order.fromJson(json);
    }).toList();
  }

  Future<List<Payment>> _getPaymentsForOrders(List<String> orderIds) async {
    if (orderIds.isEmpty) return [];
    final data = await _client
        .from('payments')
        .select()
        .inFilter('order_id', orderIds)
        .order('created_at', ascending: false);

    return data.map((json) => Payment.fromJson(json)).toList();
  }

  Future<List<OrderItem>> _getItemsForOrders(List<String> orderIds) async {
    if (orderIds.isEmpty) return [];
    final data = await _client
        .from('order_items')
        .select('''
          id,
          order_id,
          product_id,
          quantity,
          quantity_delivered,
          unit_price,
          discount_amount,
          subtotal,
          price_type,
          notes,
          delivered_at,
          created_at,
          product:products(name, code, presentation)
        ''')
        .inFilter('order_id', orderIds)
        .order('created_at');

    return data.map((json) {
      final product = json['product'] as Map<String, dynamic>?;
      json['product_name'] = product?['name'];
      json['product_code'] = product?['code'];
      json['product_presentation'] = product?['presentation'];
      return OrderItem.fromJson(json);
    }).toList();
  }
}
