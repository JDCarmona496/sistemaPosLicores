import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

enum OrderItemPriceType { retail, wholesale, fractional }

extension OrderItemPriceTypeX on OrderItemPriceType {
  String get label {
    switch (this) {
      case OrderItemPriceType.retail:
        return 'Detal';
      case OrderItemPriceType.wholesale:
        return 'Mayorista';
      case OrderItemPriceType.fractional:
        return 'Fraccionado';
    }
  }

  String get dbValue => name;
}

OrderItemPriceType? _orderItemPriceTypeFromDb(String? value) {
  if (value == null) return null;
  return OrderItemPriceType.values.cast<OrderItemPriceType?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    required String productId,
    @Default(0) int quantity,
    @Default(0) int quantityDelivered,
    @Default(0) double unitPrice,
    @Default(0) double discountAmount,
    @Default(0) double subtotal,
    @Default(OrderItemPriceType.retail) OrderItemPriceType priceType,
    String? notes,
    DateTime? deliveredAt,
    String? productName,
    String? productCode,
    String? productPresentation,
    DateTime? createdAt,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      OrderItem._fromJson(json);

  static OrderItem _fromJson(Map<String, dynamic> json) {
    return _$OrderItemFromJson({
      ...json,
      'orderId': jsonStringRequired(json['order_id']),
      'productId': jsonStringRequired(json['product_id']),
      'quantity': jsonInt(json['quantity']),
      'quantityDelivered': jsonInt(json['quantity_delivered']),
      'unitPrice': jsonDouble(json['unit_price']),
      'discountAmount': jsonDouble(json['discount_amount']),
      'subtotal': jsonDouble(json['subtotal']),
      'priceType': jsonEnum(
        json['price_type'],
        _orderItemPriceTypeFromDb,
        defaultValue: OrderItemPriceType.retail,
      ).name,
      'notes': jsonString(json['notes']),
      'deliveredAt': jsonDateTime(json['delivered_at'])?.toIso8601String(),
      'productName': jsonString(json['product_name']),
      'productCode': jsonString(json['product_code']),
      'productPresentation': jsonString(json['product_presentation']),
      'createdAt': jsonDateTime(json['created_at'])?.toIso8601String(),
    });
  }
}

extension OrderItemExtension on OrderItem {
  double get total => subtotal;
  int get pendingQuantity => quantity - quantityDelivered;
  bool get isFullyDelivered => quantityDelivered >= quantity;
  bool get isWholesalePrice => priceType == OrderItemPriceType.wholesale;
  bool get isFractionalPrice => priceType == OrderItemPriceType.fractional;
}
