import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

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

BasketStatus? _basketStatusFromDb(String value) {
  switch (value) {
    case 'deposit_held':
      return BasketStatus.depositHeld;
    default:
      return BasketStatus.values.cast<BasketStatus?>().firstWhere(
            (e) => e?.name == value,
            orElse: () => null,
          );
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
      'customerId': jsonStringRequired(json['customer_id']),
      'productId': jsonStringRequired(json['product_id']),
      'quantityOut': jsonInt(json['quantity_out']),
      'quantityReturned': jsonInt(json['quantity_returned']),
      'depositAmount': jsonDouble(json['deposit_amount']),
      'status': jsonEnum(
        json['status'],
        _basketStatusFromDb,
        defaultValue: BasketStatus.outstanding,
      ).name,
      'orderId': jsonString(json['order_id']),
      'returnedAt': jsonDateTime(json['returned_at'])?.toIso8601String(),
      'createdAt': jsonDateTime(json['created_at'])?.toIso8601String(),
      'updatedAt': jsonDateTime(json['updated_at'])?.toIso8601String(),
    });
  }
}
