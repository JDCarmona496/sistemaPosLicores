import 'package:applicoresestacion/data/providers/order_cart_providers.dart';
import 'package:applicoresestacion/domain/models/customer.dart';
import 'package:applicoresestacion/domain/models/order.dart';
import 'package:applicoresestacion/domain/models/order_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests del carrito de pedido actual.
///
/// Spec: spec del carrito (criterios AC-1..AC-14 documentados en cada grupo).
/// El notifier es lógica pura de Dart: se instancia directo, sin Supabase.
void main() {
  late CurrentOrderCartNotifier cart;

  setUp(() {
    cart = CurrentOrderCartNotifier();
  });

  OrderItem addSample({
    String productId = 'p1',
    String productName = 'Aguardiente',
    double price = 25000,
    int quantity = 1,
    OrderItemPriceType priceType = OrderItemPriceType.retail,
    double discountAmount = 0,
  }) {
    cart.addItem(
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity,
      priceType: priceType,
      discountAmount: discountAmount,
    );
    return cart.state.items.last;
  }

  group('AC-1: addItem agrega un item nuevo a un carrito vacio', () {
    test('agrega el item con cantidad, precio y subtotal correctos', () {
      addSample(price: 25000, quantity: 2);

      expect(cart.state.items, hasLength(1));
      final item = cart.state.items.first;
      expect(item.productId, 'p1');
      expect(item.quantity, 2);
      expect(item.unitPrice, 25000);
      expect(item.subtotal, 50000);
      expect(item.priceType, OrderItemPriceType.retail);
    });
  });

  group('AC-2: addItem fusiona cantidad con mismo productId + priceType', () {
    test('no duplica el item, suma las cantidades', () {
      addSample(quantity: 2);
      addSample(quantity: 3);

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.first.quantity, 5);
    });

    test('recalcula el subtotal con la cantidad fusionada', () {
      addSample(price: 10000, quantity: 1);
      addSample(price: 10000, quantity: 2);

      expect(cart.state.items.first.subtotal, 30000);
    });
  });

  group('AC-3: addItem NO fusiona cuando el priceType difiere', () {
    test('mismo producto con distinto tipo de precio crea dos items', () {
      addSample(priceType: OrderItemPriceType.retail);
      addSample(
        price: 22000,
        priceType: OrderItemPriceType.wholesale,
      );

      expect(cart.state.items, hasLength(2));
    });
  });

  group('AC-4: incrementItem', () {
    test('crea el item con cantidad 1 si no existe', () {
      cart.incrementItem(
        productId: 'p1',
        productName: 'Ron',
        price: 40000,
        priceType: OrderItemPriceType.retail,
      );

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.first.quantity, 1);
    });

    test('incrementa la cantidad si el item ya existe', () {
      addSample(quantity: 2);
      cart.incrementItem(
        productId: 'p1',
        price: 25000,
        priceType: OrderItemPriceType.retail,
      );

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.first.quantity, 3);
    });
  });

  group('AC-5: incrementItem sin productName y sin item existente', () {
    test('no hace nada (no puede crear el item sin nombre)', () {
      cart.incrementItem(
        productId: 'p1',
        price: 25000,
        priceType: OrderItemPriceType.retail,
      );

      expect(cart.state.items, isEmpty);
    });
  });

  group('AC-6: decrementItem', () {
    test('resta 1 a la cantidad', () {
      addSample(quantity: 3);
      cart.decrementItem(
        productId: 'p1',
        priceType: OrderItemPriceType.retail,
      );

      expect(cart.state.items.first.quantity, 2);
    });

    test('al llegar a 0 elimina el item', () {
      addSample(quantity: 1);
      cart.decrementItem(
        productId: 'p1',
        priceType: OrderItemPriceType.retail,
      );

      expect(cart.state.items, isEmpty);
    });

    test('solo afecta el item del priceType indicado', () {
      addSample(quantity: 1, priceType: OrderItemPriceType.retail);
      addSample(
        price: 22000,
        priceType: OrderItemPriceType.wholesale,
      );

      cart.decrementItem(
        productId: 'p1',
        priceType: OrderItemPriceType.retail,
      );

      expect(cart.state.items, hasLength(1));
      expect(
        cart.state.items.first.priceType,
        OrderItemPriceType.wholesale,
      );
    });
  });

  group('AC-7: updateItemQuantity', () {
    test('con cantidad > 0 actualiza cantidad y subtotal', () {
      final item = addSample(price: 10000, quantity: 1);
      cart.updateItemQuantity(item.id, 4);

      expect(cart.state.items.first.quantity, 4);
      expect(cart.state.items.first.subtotal, 40000);
    });

    test('con cantidad 0 elimina el item', () {
      final item = addSample();
      cart.updateItemQuantity(item.id, 0);

      expect(cart.state.items, isEmpty);
    });

    test('con cantidad negativa elimina el item', () {
      final item = addSample();
      cart.updateItemQuantity(item.id, -3);

      expect(cart.state.items, isEmpty);
    });

    test('respeta el descuento al recalcular el subtotal', () {
      final item = addSample(price: 10000, quantity: 2, discountAmount: 5000);
      cart.updateItemQuantity(item.id, 3);

      // (10000 * 3) - 5000
      expect(cart.state.items.first.subtotal, 25000);
    });
  });

  group('AC-8: updateItemPriceType', () {
    test('cambia el tipo de precio del item', () {
      final item = addSample();
      cart.updateItemPriceType(item.id, OrderItemPriceType.cold);

      expect(cart.state.items.first.priceType, OrderItemPriceType.cold);
    });

    test('no hace nada si el tipo es el mismo', () {
      final item = addSample();
      cart.updateItemPriceType(item.id, OrderItemPriceType.retail);

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.first.quantity, 1);
    });

    test('fusiona con el item existente del nuevo tipo de precio', () {
      addSample(quantity: 2, priceType: OrderItemPriceType.retail);
      final wholesale = addSample(
        price: 22000,
        quantity: 3,
        priceType: OrderItemPriceType.wholesale,
      );

      final retail = cart.state.items
          .firstWhere((i) => i.priceType == OrderItemPriceType.retail);
      cart.updateItemPriceType(retail.id, OrderItemPriceType.wholesale);

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.first.quantity, 5); // 2 + 3
      expect(
        cart.state.items.first.priceType,
        OrderItemPriceType.wholesale,
      );
      // Conserva el precio unitario del item mayorista original
      expect(cart.state.items.first.unitPrice, wholesale.unitPrice);
    });
  });

  group('AC-9: updateItemDiscount', () {
    test('aplica el descuento y recalcula el subtotal', () {
      final item = addSample(price: 10000, quantity: 2);
      cart.updateItemDiscount(item.id, 4000);

      expect(cart.state.items.first.discountAmount, 4000);
      expect(cart.state.items.first.subtotal, 16000);
    });

    test('fija en 0 un descuento negativo', () {
      final item = addSample(price: 10000, quantity: 2);
      cart.updateItemDiscount(item.id, -500);

      expect(cart.state.items.first.discountAmount, 0);
    });

    test('fija en el maximo un descuento mayor al total del item', () {
      final item = addSample(price: 10000, quantity: 2);
      cart.updateItemDiscount(item.id, 999999);

      expect(cart.state.items.first.discountAmount, 20000);
      expect(cart.state.items.first.subtotal, 0);
    });
  });

  group('AC-10: removeItem', () {
    test('elimina solo el item indicado', () {
      addSample(productId: 'p1');
      final other = addSample(productId: 'p2', productName: 'Cerveza');

      cart.removeItem(other.id);

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.first.productId, 'p1');
    });
  });

  group('AC-11: totales del estado', () {
    test('subtotal suma unitPrice * quantity de todos los items', () {
      addSample(price: 10000, quantity: 2); // 20000
      addSample(productId: 'p2', price: 5000, quantity: 3); // 15000

      expect(cart.state.subtotal, 35000);
    });

    test('total = subtotal - descuentos + domicilio', () {
      addSample(price: 20000, quantity: 1, discountAmount: 2000);
      cart.setDeliveryFee(5000);

      expect(cart.state.subtotal, 20000);
      expect(cart.state.discountAmount, 2000);
      expect(cart.state.total, 23000); // 20000 - 2000 + 5000
    });

    test('itemCount refleja la cantidad de lineas del carrito', () {
      addSample();
      addSample(productId: 'p2');

      expect(cart.state.itemCount, 2);
    });
  });

  group('AC-12: setCustomer', () {
    test('asigna los datos del cliente', () {
      cart.setCustomer(
        id: 'c1',
        name: 'Juan Perez',
        type: CustomerType.frequent,
        address: 'Calle 1 # 2-3',
      );

      expect(cart.state.customerId, 'c1');
      expect(cart.state.customerName, 'Juan Perez');
      expect(cart.state.customerType, CustomerType.frequent);
      expect(cart.state.customerAddress, 'Calle 1 # 2-3');
    });

    test('con id null limpia todos los datos del cliente', () {
      cart.setCustomer(
        id: 'c1',
        name: 'Juan Perez',
        type: CustomerType.frequent,
        address: 'Calle 1 # 2-3',
      );
      cart.setCustomer(id: null, name: null, type: null, address: null);

      expect(cart.state.customerId, isNull);
      expect(cart.state.customerName, isNull);
      expect(cart.state.customerType, isNull);
      expect(cart.state.customerAddress, isNull);
    });
  });

  group('AC-13: clearCart', () {
    test('resetea al estado inicial', () {
      addSample();
      cart.setCustomer(id: 'c1', name: 'Juan', type: CustomerType.credit);
      cart.setSaleType(SaleType.credit);
      cart.setDeliveryType(DeliveryType.delivery);
      cart.setDeliveryFee(5000);
      cart.setNotes('nota');
      cart.setDeliveryAddress('direccion');

      cart.clearCart();

      final s = cart.state;
      expect(s.items, isEmpty);
      expect(s.customerId, isNull);
      expect(s.saleType, SaleType.cash);
      expect(s.deliveryType, DeliveryType.inStore);
      expect(s.deliveryFee, 0);
      expect(s.notes, isNull);
      expect(s.deliveryAddress, isNull);
    });
  });

  group('AC-14: isOccasionalCustomer', () {
    test('es true sin cliente asignado', () {
      expect(cart.state.isOccasionalCustomer, isTrue);
    });

    test('es true con cliente tipo occasional', () {
      cart.setCustomer(
        id: 'c1',
        name: 'Ocasional',
        type: CustomerType.occasional,
      );

      expect(cart.state.isOccasionalCustomer, isTrue);
    });

    test('es false con cliente registrado no ocasional', () {
      cart.setCustomer(
        id: 'c1',
        name: 'Juan',
        type: CustomerType.frequent,
      );

      expect(cart.state.isOccasionalCustomer, isFalse);
    });
  });

  group('AC-15: coordenadas de entrega', () {
    test('setDeliveryCoordinates guarda latitud y longitud', () {
      cart.setDeliveryCoordinates(3.5373, -76.3036);

      expect(cart.state.deliveryLatitude, closeTo(3.5373, 0.0001));
      expect(cart.state.deliveryLongitude, closeTo(-76.3036, 0.0001));
      expect(cart.state.hasDeliveryCoordinates, isTrue);
    });

    test('hasDeliveryCoordinates es false sin coordenadas', () {
      expect(cart.state.hasDeliveryCoordinates, isFalse);
    });

    test('editar la direccion manualmente invalida las coordenadas', () {
      cart.setDeliveryCoordinates(3.5373, -76.3036);
      cart.setDeliveryAddress('Direccion corregida');

      expect(cart.state.deliveryAddress, 'Direccion corregida');
      expect(cart.state.hasDeliveryCoordinates, isFalse);
    });

    test('clearCart limpia las coordenadas', () {
      cart.setDeliveryCoordinates(3.5373, -76.3036);
      cart.clearCart();

      expect(cart.state.hasDeliveryCoordinates, isFalse);
    });

    test('setDeliveryAddress desde cliente conserva coordenadas', () {
      cart.setDeliveryCoordinates(3.5373, -76.3036);
      cart.setDeliveryAddress('Direccion del cliente', clearCoordinates: false);

      expect(cart.state.deliveryAddress, 'Direccion del cliente');
      expect(cart.state.hasDeliveryCoordinates, isTrue);
      expect(cart.state.deliveryLatitude, closeTo(3.5373, 0.0001));
      expect(cart.state.deliveryLongitude, closeTo(-76.3036, 0.0001));
    });
  });
}
