import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/product_providers.dart';
import '../../../../../domain/models/order_item.dart';
import 'price_type_style.dart';
import 'quantity_selector.dart';

/// Panel del carrito: lista de ítems, sección de entrega y notas.
class OrderCartPanel extends ConsumerWidget {
  final TextEditingController addressController;
  final TextEditingController deliveryFeeController;
  final TextEditingController notesController;

  const OrderCartPanel({
    super.key,
    required this.addressController,
    required this.deliveryFeeController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, cartState),
                  const SizedBox(height: 12),
                  if (cartState.items.isEmpty)
                    _buildEmptyState(context)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) =>
                          _buildCartItem(context, ref, cartState, cartState.items[index]),
                    ),
                  const Divider(),
                  _buildDeliverySection(ref),
                  const SizedBox(height: 12),
                  _buildNotesSection(ref),
                ],
              ),
            ),
          ),
          if (cartState.items.isNotEmpty)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Vaciar carrito',
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _confirmClearCart(context, ref),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CurrentOrderCartState cartState) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.shopping_cart, color: colorScheme.primary),
        const SizedBox(width: 8),
        const Text(
          'Carrito',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        if (cartState.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${cartState.items.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        // Espacio para no chocar con el botón de vaciar en la esquina.
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: Colors.grey.shade700),
            const SizedBox(height: 8),
            Text(
              'El carrito está vacío',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_sweep,
            color: Theme.of(context).colorScheme.error),
        title: const Text('Vaciar carrito'),
        content: const Text('¿Eliminar todos los productos del pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(currentOrderCartProvider.notifier).clearCart();
    }
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref,
      CurrentOrderCartState cartState, OrderItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final stock =
        ref.watch(productByIdProvider(item.productId)).valueOrNull?.stockCurrent;

    // El stock disponible para este ítem descuenta lo que el mismo
    // producto ya ocupa en el carrito con otros tipos de precio.
    final othersQty = cartState.items
        .where((i) => i.productId == item.productId && i.id != item.id)
        .fold(0, (sum, i) => sum + i.quantity);
    final maxQty = stock == null ? null : (stock - othersQty).clamp(0, 1 << 31);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName ?? 'Producto',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ref
                      .read(currentOrderCartProvider.notifier)
                      .removeItem(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close,
                        size: 18, color: colorScheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildItemPriceTypeChip(context, ref, item),
                const SizedBox(width: 8),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(0)} c/u',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuantitySelector(
                  quantity: item.quantity,
                  maxQuantity: maxQty,
                  onChanged: (qty) => ref
                      .read(currentOrderCartProvider.notifier)
                      .updateItemQuantity(item.id, qty),
                  onLimitExceeded: (message) =>
                      _showSnack(context, message, isError: true),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

  Widget _buildItemPriceTypeChip(
      BuildContext context, WidgetRef ref, OrderItem item) {
    final color = item.priceType.color;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showItemPriceTypeSelector(context, ref, item),
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

  Future<void> _showItemPriceTypeSelector(
      BuildContext context, WidgetRef ref, OrderItem item) async {
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

  Widget _buildDeliverySection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_shipping, size: 18),
            SizedBox(width: 8),
            Text(
              'Entrega',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección de entrega',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) => ref
              .read(currentOrderCartProvider.notifier)
              .setDeliveryAddress(value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: deliveryFeeController,
          decoration: const InputDecoration(
            labelText: 'Costo de domicilio',
            prefixIcon: Icon(Icons.delivery_dining),
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final fee = double.tryParse(value) ?? 0;
            ref.read(currentOrderCartProvider.notifier).setDeliveryFee(fee);
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection(WidgetRef ref) {
    return TextField(
      controller: notesController,
      decoration: const InputDecoration(
        labelText: 'Notas / Observaciones',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 2,
      onChanged: (value) =>
          ref.read(currentOrderCartProvider.notifier).setNotes(value),
    );
  }

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
