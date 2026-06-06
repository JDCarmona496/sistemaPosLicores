import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_basket.freezed.dart';
part 'customer_basket.g.dart';

enum BasketStatus { outstanding, returned, charged, deposit_held }

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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? returnedAt,
  }) = _CustomerBasket;

  factory CustomerBasket.fromJson(Map<String, dynamic> json) =>
      _$CustomerBasketFromJson(json);

  Map<String, dynamic> toSupabaseJson() {
    final json = <String, dynamic>{
      'customer_id': customerId,
      'product_id': productId,
      'quantity_out': quantityOut,
      'quantity_returned': quantityReturned,
      'deposit_amount': depositAmount,
      'status': status.name,
    };

    if (orderId != null && orderId!.isNotEmpty) {
      json['order_id'] = orderId;
    }

    if (returnedAt != null) {
      json['returned_at'] = returnedAt!.toIso8601String();
    }

    return json;
  }
}
