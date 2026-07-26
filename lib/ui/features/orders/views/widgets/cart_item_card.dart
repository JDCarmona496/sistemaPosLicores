import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/product_providers.dart';
import '../../../../../domain/models/order_item.dart';
import 'price_type_style.dart';
import 'quantity_selector.dart';

/// Tarjeta de ítem del carrito con precio tipo, cantidad y subtotal.
class CartItemCard extends ConsumerWidget {
  final OrderItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartState = ref.watch(currentOrderCartProvider);
    final product = ref.watch(productByIdProvider(item.productId)).valueOrNull;
    final stock = product?.stockCurrent;
    final productName = item.productName?.isNotEmpty == true
        ? item.productName!
        : (product?.name ?? 'Producto');
    final othersQty = cartState.items
        .where((i) => i.productId == item.productId && i.id != item.id)
        .fold(0, (sum, i) => sum + i.quantity);
    final maxQty = stock == null ? null : (stock - othersQty).clamp(0, 1 << 31);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: colorScheme.error),
                  onPressed: () => ref
                      .read(currentOrderCartProvider.notifier)
                      .removeItem(item.id),
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _ItemPriceTypeChip(item: item),
                const SizedBox(width: 8),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(0)} c/u',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuantitySelector(
                  quantity: item.quantity,
                  maxQuantity: maxQty,
                  onChanged: (qty) => ref
                      .read(currentOrderCartProvider.notifier)
                      .updateItemQuantity(item.id, qty),
                  onLimitExceeded: (message) => _showSnack(context, message),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _ItemPriceTypeChip extends ConsumerWidget {
  final OrderItem item;

  const _ItemPriceTypeChip({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.priceType.color;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPriceTypeSelector(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.priceType.icon, size: 12, color: color.shade700),
            const SizedBox(width: 4),
            Text(
              item.priceType.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.edit, size: 10, color: color.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _showPriceTypeSelector(BuildContext context, WidgetRef ref) async {
    final selected = await showDialog<OrderItemPriceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar tipo de precio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderItemPriceType.values.map((type) {
            final selected = type == item.priceType;
            return ListTile(
              leading: Icon(type.icon, color: type.color.shade700),
              title: Text(type.label),
              trailing: selected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, type),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null && selected != item.priceType) {
      ref
          .read(currentOrderCartProvider.notifier)
          .updateItemPriceType(item.id, selected);
    }
  }
}
