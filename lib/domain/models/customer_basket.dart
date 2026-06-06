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
      _$CustomerBasketFromJson(json);
}
