import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_basket.freezed.dart';
part 'customer_basket.g.dart';

enum BasketStatus { outstanding, returned, charged, depositHeld }

extension BasketStatusX on BasketStatus {
  String get label {
    switch (this) {
      case BasketStatus.outstanding:
        return 'Pendiente';
      case BasketStatus.returned:
        return 'Devuelta';
      case BasketStatus.charged:
        return 'Cobrada';
      case BasketStatus.depositHeld:
        return 'Depósito Retenido';
    }
  }

  String get dbValue {
    switch (this) {
      case BasketStatus.outstanding:
        return 'outstanding';
      case BasketStatus.returned:
        return 'returned';
      case BasketStatus.charged:
        return 'charged';
      case BasketStatus.depositHeld:
        return 'deposit_held';
    }
  }
}

String _basketStatusFromDb(dynamic value) {
  if (value == null) return 'outstanding';
  final str = value.toString();
  switch (str) {
    case 'deposit_held':
      return 'depositHeld';
    default:
      return str;
  }
}

@freezed
class CustomerBasket with _$CustomerBasket {
  const factory CustomerBasket({
    required String id,
    required String customerId,
    required String productId,
    required int quantityOut,
    @Default(0) int quantityReturned,
    @Default(0) double depositAmount,
    @Default(BasketStatus.outstanding) BasketStatus status,
    String? orderId,
    DateTime? returnedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CustomerBasket;

  factory CustomerBasket.fromJson(Map<String, dynamic> json) =>
      CustomerBasket._fromJson(json);

  static CustomerBasket _fromJson(Map<String, dynamic> json) {
    return _$CustomerBasketFromJson({
      ...json,
      'customerId': json['customer_id'],
      'productId': json['product_id'],
      'quantityOut': json['quantity_out'] ?? 0,
      'quantityReturned': json['quantity_returned'] ?? 0,
      'depositAmount': (json['deposit_amount'] as num?)?.toDouble() ?? 0,
      'status': _basketStatusFromDb(json['status']),
      'orderId': json['order_id'],
      'returnedAt': json['returned_at'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}
