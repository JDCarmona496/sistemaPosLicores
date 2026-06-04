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

enum SaleType { cash, credit }

enum DeliveryType { inStore, delivery }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required int orderNumber,
    required String sellerId,
    required OrderStatus status,
    required SaleType saleType,
    required DeliveryType deliveryType,
    required double subtotal,
    required double discountAmount,
    required double total,
    String? customerId,
    String? deliveryPersonId,
    double? deliveryFee,
    String? notes,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPhotoUrl,
    String? cancelledReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    DateTime? deliveredAt,
    @Default(0) int editCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
