import 'customer_basket.dart';

extension CustomerBasketSupabaseExtension on CustomerBasket {
  Map<String, dynamic> toSupabaseJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'customer_id': customerId,
      'product_id': productId,
      'quantity_out': quantityOut,
      'quantity_returned': quantityReturned,
      'deposit_amount': depositAmount,
      'status': status.dbValue,
    };

    if (includeId) json['id'] = id;
    if (orderId != null && orderId!.isNotEmpty) json['order_id'] = orderId;
    if (returnedAt != null) json['returned_at'] = returnedAt!.toIso8601String();

    return json;
  }

  int get pendingQuantity => quantityOut - quantityReturned;
  bool get isFullyReturned => quantityReturned >= quantityOut;
  bool get hasPending => pendingQuantity > 0;
}
