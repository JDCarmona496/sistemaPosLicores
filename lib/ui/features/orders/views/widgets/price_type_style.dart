import 'package:flutter/material.dart';

import '../../../../../domain/models/order_item.dart';

/// Estilo visual centralizado por tipo de precio.
/// Fuente única de verdad para colores e iconos en toda la UI de pedidos.
extension OrderItemPriceTypeStyle on OrderItemPriceType {
  MaterialColor get color {
    switch (this) {
      case OrderItemPriceType.retail:
        return Colors.green;
      case OrderItemPriceType.wholesale:
        return Colors.purple;
      case OrderItemPriceType.cold:
        return Colors.lightBlue;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderItemPriceType.retail:
        return Icons.sell;
      case OrderItemPriceType.wholesale:
        return Icons.inventory_2;
      case OrderItemPriceType.cold:
        return Icons.ac_unit;
    }
  }
}
