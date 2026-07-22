import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_extensions.dart';
import '../../domain/models/order_item.dart';

class OrderRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Order>> getAll({
    String? search,
    OrderStatus? status,
    SaleType? saleType,
    DeliveryType? deliveryType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('orders').select('''
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
      ''');

    if (search != null && search.isNotEmpty) {
      final orderNumber = int.tryParse(search);
      if (orderNumber != null) {
        query = query.eq('order_number', orderNumber);
      } else {
        query = query.or(
          'customer.full_name.ilike.%$search%,customer.phone.ilike.%$search%',
        );
      }
    }

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    if (saleType != null) {
      query = query.eq('sale_type', saleType.dbValue);
    }

    if (deliveryType != null) {
      query = query.eq('delivery_type', deliveryType.dbValue);
    }

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map((json) {
      final customer = json['customer'] as Map<String, dynamic>?;
      json['customer_name'] = customer?['full_name'];
      json['customer_phone'] = customer?['phone'];
      return Order.fromJson(json);
    }).toList();
  }

  Future<Order?> getById(String id) async {
    try {
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
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;

      final customer = data['customer'] as Map<String, dynamic>?;
      data['customer_name'] = customer?['full_name'];
      data['customer_phone'] = customer?['phone'];
      data['customer_address'] = customer?['address'];

      return Order.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<OrderItem>> getItems(String orderId) async {
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
        .eq('order_id', orderId)
        .order('created_at');

    return data.map((json) {
      final product = json['product'] as Map<String, dynamic>?;
      json['product_name'] = product?['name'];
      json['product_code'] = product?['code'];
      json['product_presentation'] = product?['presentation'];
      return OrderItem.fromJson(json);
    }).toList();
  }

  Future<Order> create({
    required String sellerId,
    String? customerId,
    required SaleType saleType,
    required DeliveryType deliveryType,
    required List<OrderItem> items,
    String? notes,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double deliveryFee = 0,
  }) async {
    try {
      final orderId = await _client.rpc<String>(
        'create_order_with_items',
        params: {
          'p_customer_id': customerId,
          'p_seller_id': sellerId,
          'p_sale_type': saleType.dbValue,
          'p_delivery_type': deliveryType.dbValue,
          'p_items': items.toRpcJson(),
          'p_notes': notes,
          'p_delivery_address': deliveryAddress,
          'p_delivery_latitude': deliveryLatitude,
          'p_delivery_longitude': deliveryLongitude,
          'p_delivery_fee': deliveryFee,
        },
      );

      final order = await getById(orderId);
      if (order == null) {
        throw Exception('No se pudo recuperar el pedido creado');
      }
      return order;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'crear el pedido');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al crear el pedido: $e');
    }
  }

  Future<Order> update(Order order) async {
    try {
      final data = order.toSupabaseJson();

      final result = await _client
          .from('orders')
          .update(data)
          .eq('id', order.id)
          .select()
          .single();

      return Order.fromJson(result);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'actualizar el pedido');
    } catch (e) {
      throw Exception('Error inesperado al actualizar el pedido: $e');
    }
  }

  Future<List<Order>> getAssignedOrders({
    required String deliveryPersonId,
    List<OrderStatus>? statuses,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = _client.from('orders').select('''
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
        created_at,
        updated_at,
        customer:customers(full_name, phone, address)
      ''');

    query = query.eq('delivery_person_id', deliveryPersonId);

    if (statuses != null && statuses.isNotEmpty) {
      final values = statuses.map((s) => s.dbValue).toList();
      query = query.inFilter('status', values);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map((json) {
      final customer = json['customer'] as Map<String, dynamic>?;
      json['customer_name'] = customer?['full_name'];
      json['customer_phone'] = customer?['phone'];
      json['customer_address'] = customer?['address'];
      return Order.fromJson(json);
    }).toList();
  }

  Future<Order> recordDeliveryEvidence({
    required String orderId,
    String? photoUrl,
    String? signatureBase64,
    DateTime? deliveredAt,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (photoUrl != null) updates['delivery_photo_url'] = photoUrl;
      if (signatureBase64 != null) updates['delivery_signature'] = signatureBase64;
      if (deliveredAt != null) {
        updates['delivered_at'] = deliveredAt.toIso8601String();
      }
      if (updates.isEmpty) {
        throw Exception('No hay evidencia para registrar');
      }

      final result = await _client
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .select()
          .single();

      return Order.fromJson(result);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'registrar evidencia de entrega');
    } catch (e) {
      throw Exception('Error inesperado al registrar evidencia: $e');
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      await _client
          .from('orders')
          .update({'status': status.dbValue})
          .eq('id', orderId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cambiar el estado del pedido');
    } catch (e) {
      throw Exception('Error inesperado al cambiar el estado: $e');
    }
  }

  Future<void> markItemsDelivered({
    required String orderId,
    required List<({String orderItemId, int quantityDelivered})> items,
  }) async {
    try {
      await _client.rpc(
        'mark_items_delivered',
        params: {
          'p_order_id': orderId,
          'p_delivered_items': items
              .map((i) => {
                    'order_item_id': i.orderItemId,
                    'quantity_delivered': i.quantityDelivered,
                  })
              .toList(),
        },
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'registrar entrega');
    } catch (e) {
      throw Exception('Error inesperado al registrar entrega: $e');
    }
  }

  Future<void> assignDeliveryPerson(String orderId, String deliveryPersonId) async {
    try {
      await _client
          .from('orders')
          .update({
            'delivery_person_id': deliveryPersonId,
            'status': OrderStatus.inTransit.dbValue,
          })
          .eq('id', orderId);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e, 'asignar domiciliario');
    } catch (e) {
      throw Exception('Error inesperado al asignar domiciliario: $e');
    }
  }

  Future<void> updateDeliveryPerson(String orderId, String deliveryPersonId) async {
    try {
      await _client
          .from('orders')
          .update({'delivery_person_id': deliveryPersonId})
          .eq('id', orderId);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e, 'cambiar domiciliario');
    } catch (e) {
      throw Exception('Error inesperado al cambiar domiciliario: $e');
    }
  }

  Future<void> cancel({
    required String orderId,
    required String reason,
    required String cancelledBy,
  }) async {
    try {
      await _client.rpc(
        'cancel_order',
        params: {
          'p_order_id': orderId,
          'p_reason': reason,
          'p_cancelled_by': cancelledBy,
        },
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'cancelar el pedido');
    } catch (e) {
      throw Exception('Error inesperado al cancelar el pedido: $e');
    }
  }

  Future<void> editItem({
    required String orderId,
    required String orderItemId,
    required int newQuantity,
    required String editedBy,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'edit_order_item',
        params: {
          'p_order_id': orderId,
          'p_order_item_id': orderItemId,
          'p_new_quantity': newQuantity,
          'p_edited_by': editedBy,
          'p_reason': reason,
        },
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'editar el item');
    } catch (e) {
      throw Exception('Error inesperado al editar el item: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('orders').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e, 'eliminar el pedido');
    } catch (e) {
      throw Exception('Error inesperado al eliminar el pedido: $e');
    }
  }

  Exception _handlePostgrestError(PostgrestException e, String action) {
    final message = e.message.toLowerCase();

    if (message.contains('stock insuficiente')) {
      return Exception('Stock insuficiente para uno o más productos.');
    }
    if (message.contains('no se puede cancelar un pedido entregado')) {
      return Exception('No se puede cancelar un pedido que ya fue entregado.');
    }
    if (message.contains('solo se pueden editar pedidos')) {
      return Exception('Solo se pueden editar pedidos pendientes o en preparación.');
    }
    if (message.contains('permission denied') || message.contains('rls')) {
      return Exception(
          'No tienes permisos para $action. Contacta al administrador.');
    }

    return Exception('Error al $action: ${e.message}');
  }
}
