import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../domain/models/order_item.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Carrito',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (cartState.items.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => ref
                          .read(currentOrderCartProvider.notifier)
                          .clearCart(),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Vaciar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (cartState.items.isEmpty)
                SizedBox(
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
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) =>
                      _buildCartItem(context, ref, cartState.items[index]),
                ),
              const Divider(),
              _buildDeliverySection(ref),
              const SizedBox(height: 12),
              _buildNotesSection(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, OrderItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          '${item.quantity}',
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        item.productName ?? 'Producto',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      subtitle: Wrap(
        spacing: 8,
        children: [
          Text(
            '\$${item.unitPrice.toStringAsFixed(0)} c/u',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          _buildItemPriceTypeChip(context, ref, item),
        ],
      ),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '\$${item.subtotal.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => ref
                      .read(currentOrderCartProvider.notifier)
                      .updateItemQuantity(item.id, item.quantity + 1),
                  child: const Icon(Icons.add, size: 18),
                ),
                InkWell(
                  onTap: () => ref
                      .read(currentOrderCartProvider.notifier)
                      .updateItemQuantity(item.id, item.quantity - 1),
                  child: const Icon(Icons.remove, size: 18),
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
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showItemPriceTypeSelector(context, ref, item),
      child: Chip(
        label: Text(
          item.priceType.label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: colorScheme.primaryContainer,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              title: Text(type.label),
              leading: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
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
        const Text(
          'Entrega',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
}
