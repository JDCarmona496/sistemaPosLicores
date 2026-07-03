import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

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

OrderStatus? _orderStatusFromDb(String value) {
  switch (value) {
    case 'in_transit':
      return OrderStatus.inTransit;
    case 'partially_delivered':
      return OrderStatus.partiallyDelivered;
    default:
      return OrderStatus.values.cast<OrderStatus?>().firstWhere(
            (e) => e?.name == value,
            orElse: () => null,
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

SaleType? _saleTypeFromDb(String value) {
  return SaleType.values.cast<SaleType?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
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

DeliveryType? _deliveryTypeFromDb(String value) {
  switch (value) {
    case 'in_store':
      return DeliveryType.inStore;
    case 'delivery':
      return DeliveryType.delivery;
    default:
      return null;
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
      'orderNumber': jsonInt(json['order_number']),
      'customerId': jsonString(json['customer_id']),
      'sellerId': jsonStringRequired(json['seller_id']),
      'deliveryPersonId': jsonString(json['delivery_person_id']),
      'status': jsonEnum(
        json['status'],
        _orderStatusFromDb,
        defaultValue: OrderStatus.pending,
      ).name,
      'saleType': jsonEnum(
        json['sale_type'],
        _saleTypeFromDb,
        defaultValue: SaleType.cash,
      ).name,
      'deliveryType': jsonEnum(
        json['delivery_type'],
        _deliveryTypeFromDb,
        defaultValue: DeliveryType.inStore,
      ).name,
      'subtotal': jsonDouble(json['subtotal']),
      'discountAmount': jsonDouble(json['discount_amount']),
      'taxAmount': jsonDouble(json['tax_amount']),
      'deliveryFee': jsonDouble(json['delivery_fee']),
      'total': jsonDouble(json['total']),
      'notes': jsonString(json['notes']),
      'deliveryAddress': jsonString(json['delivery_address']),
      'deliveryLatitude': jsonDouble(json['delivery_latitude']),
      'deliveryLongitude': jsonDouble(json['delivery_longitude']),
      'deliveryPhotoUrl': jsonString(json['delivery_photo_url']),
      'deliverySignature': jsonString(json['delivery_signature']),
      'deliveredAt': jsonDateTime(json['delivered_at']),
      'cancelledReason': jsonString(json['cancelled_reason']),
      'cancelledBy': jsonString(json['cancelled_by']),
      'cancelledAt': jsonDateTime(json['cancelled_at'])?.toIso8601String(),
      'editCount': jsonInt(json['edit_count']),
      'customerName': jsonString(json['customer_name']),
      'customerPhone': jsonString(json['customer_phone']),
      'customerAddress': jsonString(json['customer_address']),
      'createdAt': jsonDateTime(json['created_at'])?.toIso8601String(),
      'updatedAt': jsonDateTime(json['updated_at'])?.toIso8601String(),
    });
  }
}
