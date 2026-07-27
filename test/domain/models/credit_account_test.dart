import 'package:applicoresestacion/domain/models/credit_account.dart';
import 'package:applicoresestacion/domain/models/order.dart';
import 'package:applicoresestacion/domain/models/order_item.dart';
import 'package:applicoresestacion/domain/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditAccount', () {
    test('calcula balance, totalPaid e isPaid correctamente', () {
      final order = _order(total: 100000);
      final payments = [
        _payment(amount: 30000),
        _payment(amount: 20000),
      ];

      final credit = CreditAccount(order: order, payments: payments);

      expect(credit.total, 100000);
      expect(credit.totalPaid, 50000);
      expect(credit.balance, 50000);
      expect(credit.isPaid, false);
    });

    test('isPaid es true cuando los pagos cubren el total', () {
      final order = _order(total: 50000);
      final payments = [_payment(amount: 50000)];

      final credit = CreditAccount(order: order, payments: payments);

      expect(credit.balance, 0);
      expect(credit.isPaid, true);
    });

    test('detecta entrega pendiente en domicilio no entregado', () {
      final order = _order(
        total: 100000,
        deliveryType: DeliveryType.delivery,
        status: OrderStatus.inTransit,
      );
      final items = [
        _item(quantity: 10, quantityDelivered: 3),
      ];

      final credit = CreditAccount(order: order, items: items);

      expect(credit.hasPendingDelivery, true);
      expect(credit.totalQuantity, 10);
      expect(credit.totalDelivered, 3);
      expect(credit.pendingQuantity, 7);
    });

    test('no detecta entrega pendiente en pedido entregado', () {
      final order = _order(
        total: 100000,
        deliveryType: DeliveryType.delivery,
        status: OrderStatus.delivered,
      );

      final credit = CreditAccount(order: order);

      expect(credit.hasPendingDelivery, false);
    });

    test('no detecta entrega pendiente en pedido de tienda', () {
      final order = _order(
        total: 100000,
        deliveryType: DeliveryType.inStore,
        status: OrderStatus.delivered,
      );

      final credit = CreditAccount(order: order);

      expect(credit.hasPendingDelivery, false);
    });
  });
}

Order _order({
  required double total,
  DeliveryType deliveryType = DeliveryType.inStore,
  OrderStatus status = OrderStatus.delivered,
}) {
  return Order(
    id: 'order-1',
    orderNumber: 1,
    sellerId: 'seller-1',
    customerId: 'customer-1',
    total: total,
    deliveryType: deliveryType,
    status: status,
    saleType: SaleType.credit,
  );
}

Payment _payment({required double amount}) {
  return Payment(
    id: 'payment-1',
    orderId: 'order-1',
    paymentMethod: PaymentMethod.cash,
    amount: amount,
    receivedBy: 'seller-1',
  );
}

OrderItem _item({required int quantity, required int quantityDelivered}) {
  return OrderItem(
    id: 'item-1',
    orderId: 'order-1',
    productId: 'product-1',
    quantity: quantity,
    quantityDelivered: quantityDelivered,
  );
}
