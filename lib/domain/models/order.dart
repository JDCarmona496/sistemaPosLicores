import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  inTransit,
  delivered,
  partiallyDelivered,
  cancelled,
  returned,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'En preparación';
      case OrderStatus.ready:
        return 'Listo';
      case OrderStatus.inTransit:
        return 'En camino';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.partiallyDelivered:
        return 'Entrega parcial';
      case OrderStatus.cancelled:
        return 'Cancelado';
      case OrderStatus.returned:
        return 'Devuelto';
    }
  }

  String get dbValue {
    switch (this) {
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.partiallyDelivered:
        return 'partially_delivered';
      default:
        return name;
    }
  }
}

OrderStatus _orderStatusFromDb(dynamic value) {
  final str = value?.toString() ?? '';
  switch (str) {
    case 'in_transit':
      return OrderStatus.inTransit;
    case 'partially_delivered':
      return OrderStatus.partiallyDelivered;
    default:
      return OrderStatus.values.firstWhere(
        (e) => e.name == str,
        orElse: () => OrderStatus.pending,
      );
  }
}

enum SaleType { cash, credit }

extension SaleTypeX on SaleType {
  String get label {
    switch (this) {
      case SaleType.cash:
        return 'Contado';
      case SaleType.credit:
        return 'Crédito';
    }
  }

  String get dbValue => name;
}

enum DeliveryType { inStore, delivery }

extension DeliveryTypeX on DeliveryType {
  String get label {
    switch (this) {
      case DeliveryType.inStore:
        return 'En tienda';
      case DeliveryType.delivery:
        return 'Domicilio';
    }
  }

  String get dbValue {
    switch (this) {
      case DeliveryType.inStore:
        return 'in_store';
      case DeliveryType.delivery:
        return 'delivery';
    }
  }
}

DeliveryType _deliveryTypeFromDb(dynamic value) {
  final str = value?.toString() ?? '';
  switch (str) {
    case 'in_store':
      return DeliveryType.inStore;
    case 'delivery':
      return DeliveryType.delivery;
    default:
      return DeliveryType.inStore;
  }
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required int orderNumber,
    String? customerId,
    required String sellerId,
    String? deliveryPersonId,
    @Default(OrderStatus.pending) OrderStatus status,
    @Default(SaleType.cash) SaleType saleType,
    @Default(DeliveryType.inStore) DeliveryType deliveryType,
    @Default(0) double subtotal,
    @Default(0) double discountAmount,
    @Default(0) double taxAmount,
    @Default(0) double deliveryFee,
    @Default(0) double total,
    String? notes,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPhotoUrl,
    String? deliverySignature,
    DateTime? deliveredAt,
    String? cancelledReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    @Default(0) int editCount,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => Order._fromJson(json);

  static Order _fromJson(Map<String, dynamic> json) {
    return _$OrderFromJson({
      ...json,
      'orderNumber': json['order_number'],
      'customerId': json['customer_id'],
      'sellerId': json['seller_id'],
      'deliveryPersonId': json['delivery_person_id'],
      'status': _orderStatusFromDb(json['status']).name,
      'saleType': json['sale_type'],
      'deliveryType': _deliveryTypeFromDb(json['delivery_type']).name,
      'subtotal': (json['subtotal'] as num?)?.toDouble() ?? 0,
      'discountAmount': (json['discount_amount'] as num?)?.toDouble() ?? 0,
      'taxAmount': (json['tax_amount'] as num?)?.toDouble() ?? 0,
      'deliveryFee': (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      'total': (json['total'] as num?)?.toDouble() ?? 0,
      'notes': json['notes'],
      'deliveryAddress': json['delivery_address'],
      'deliveryLatitude': (json['delivery_latitude'] as num?)?.toDouble(),
      'deliveryLongitude': (json['delivery_longitude'] as num?)?.toDouble(),
      'deliveryPhotoUrl': json['delivery_photo_url'],
      'deliverySignature': json['delivery_signature'],
      'deliveredAt': json['delivered_at'],
      'cancelledReason': json['cancelled_reason'],
      'cancelledBy': json['cancelled_by'],
      'cancelledAt': json['cancelled_at'],
      'editCount': json['edit_count'] ?? 0,
      'customerName': json['customer_name'],
      'customerPhone': json['customer_phone'],
      'customerAddress': json['customer_address'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}
