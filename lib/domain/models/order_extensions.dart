import 'order.dart';
import 'order_item.dart';

extension OrderSupabaseExtension on Order {
  Map<String, dynamic> toSupabaseJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'seller_id': sellerId,
      'status': status.dbValue,
      'sale_type': saleType.dbValue,
      'delivery_type': deliveryType.dbValue,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'delivery_fee': deliveryFee,
      'total': total,
    };

    if (includeId) json['id'] = id;
    if (orderNumber > 0) json['order_number'] = orderNumber;
    if (customerId != null && customerId!.isNotEmpty) {
      json['customer_id'] = customerId;
    }
    if (deliveryPersonId != null && deliveryPersonId!.isNotEmpty) {
      json['delivery_person_id'] = deliveryPersonId;
    }
    if (notes != null && notes!.isNotEmpty) json['notes'] = notes;
    if (deliveryAddress != null && deliveryAddress!.isNotEmpty) {
      json['delivery_address'] = deliveryAddress;
    }
    if (deliveryLatitude != null) json['delivery_latitude'] = deliveryLatitude;
    if (deliveryLongitude != null) {
      json['delivery_longitude'] = deliveryLongitude;
    }
    if (deliveryPhotoUrl != null && deliveryPhotoUrl!.isNotEmpty) {
      json['delivery_photo_url'] = deliveryPhotoUrl;
    }
    if (deliverySignature != null && deliverySignature!.isNotEmpty) {
      json['delivery_signature'] = deliverySignature;
    }
    if (deliveredAt != null) json['delivered_at'] = deliveredAt!.toIso8601String();
    if (cancelledReason != null && cancelledReason!.isNotEmpty) {
      json['cancelled_reason'] = cancelledReason;
    }
    if (cancelledBy != null && cancelledBy!.isNotEmpty) {
      json['cancelled_by'] = cancelledBy;
    }
    if (cancelledAt != null) json['cancelled_at'] = cancelledAt!.toIso8601String();
    if (editCount > 0) json['edit_count'] = editCount;

    return json;
  }
}

extension OrderItemSupabaseExtension on OrderItem {
  Map<String, dynamic> toSupabaseJson({bool includeId = false}) {
    final json = <String, dynamic>{
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'quantity_delivered': quantityDelivered,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'subtotal': subtotal,
      'is_wholesale_price': isWholesalePrice,
    };

    if (includeId) json['id'] = id;
    if (notes != null && notes!.isNotEmpty) json['notes'] = notes;
    if (deliveredAt != null) json['delivered_at'] = deliveredAt!.toIso8601String();

    return json;
  }

  /// Convierte el item al formato JSON esperado por la función RPC
  /// private.create_order_with_items
  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
    };
  }
}

extension OrderItemListExtension on List<OrderItem> {
  List<Map<String, dynamic>> toRpcJson() {
    return map((item) => item.toRpcJson()).toList();
  }

  double get totalSubtotal => fold(0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => fold(0, (sum, item) => sum + item.discountAmount);
  double get totalQuantity => fold(0, (sum, item) => sum + item.quantity);
}
