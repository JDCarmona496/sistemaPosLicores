import 'package:applicoresestacion/domain/models/order.dart';
import 'package:applicoresestacion/domain/models/order_item.dart';
import 'package:applicoresestacion/domain/models/payment.dart';

/// Vista agregada de un pedido a crédito: pedido + pagos + ítems.
class CreditAccount {
  final Order order;
  final List<Payment> payments;
  final List<OrderItem> items;

  const CreditAccount({
    required this.order,
    this.payments = const [],
    this.items = const [],
  });

  double get total => order.total;

  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);

  double get balance => total - totalPaid;

  bool get isPaid => balance <= 0;

  /// Hay entrega pendiente si es domicilio y no está entregado completamente.
  bool get hasPendingDelivery {
    if (order.deliveryType != DeliveryType.delivery) return false;
    if (order.status == OrderStatus.delivered) return false;
    if (order.status == OrderStatus.completed) return false;
    if (order.status == OrderStatus.cancelled) return false;
    return true;
  }

  /// Cantidad total pedida vs entregada entre todos los ítems.
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  int get totalDelivered => items.fold(0, (sum, i) => sum + i.quantityDelivered);

  int get pendingQuantity => totalQuantity - totalDelivered;
}
