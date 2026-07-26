import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import 'cart_item_card.dart';
import 'geocode_address_button.dart';
import 'section_header.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              color: colorScheme.surfaceContainerLowest,
              padding: const EdgeInsets.all(16),
              child: SectionHeader(
                icon: Icons.shopping_cart_outlined,
                title: 'Carrito',
                trailing: cartState.items.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cartState.items.length}',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.delete_sweep,
                                color: colorScheme.error),
                            onPressed: () => _confirmClearCart(context, ref),
                            tooltip: 'Vaciar carrito',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            Expanded(
              child: cartState.items.isEmpty
                  ? _buildEmptyState(context)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartState.items.length,
                            itemBuilder: (context, index) => CartItemCard(
                              item: cartState.items[index],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DeliverySection(
                            addressController: addressController,
                            deliveryFeeController: deliveryFeeController,
                          ),
                          NotesSection(notesController: notesController),
                          const OrderSummarySection(),
                        ],
                      ),
                    ),
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

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'El carrito está vacío',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega productos desde el catálogo',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de entrega con dirección, costo de domicilio y geocodificación.
class DeliverySection extends ConsumerWidget {
  final TextEditingController addressController;
  final TextEditingController deliveryFeeController;

  const DeliverySection({
    super.key,
    required this.addressController,
    required this.deliveryFeeController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.local_shipping_outlined,
              title: 'Entrega',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Dirección de entrega',
                prefixIcon: Icon(Icons.location_on_outlined,
                    color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              maxLines: 2,
              onChanged: (value) => ref
                  .read(currentOrderCartProvider.notifier)
                  .setDeliveryAddress(value),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: GeocodeAddressButton(addressController: addressController),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deliveryFeeController,
              decoration: InputDecoration(
                labelText: 'Costo de domicilio',
                prefixIcon: Icon(Icons.delivery_dining_outlined,
                    color: colorScheme.onSurfaceVariant),
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final fee = double.tryParse(value) ?? 0;
                ref
                    .read(currentOrderCartProvider.notifier)
                    .setDeliveryFee(fee);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de notas u observaciones del pedido.
class NotesSection extends ConsumerWidget {
  final TextEditingController notesController;

  const NotesSection({super.key, required this.notesController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.note_alt_outlined,
              title: 'Notas',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.note_outlined,
                    color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (value) => ref
                  .read(currentOrderCartProvider.notifier)
                  .setNotes(value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumen de totales dentro del panel del carrito.
class OrderSummarySection extends ConsumerWidget {
  const OrderSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.primaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.receipt_outlined,
              title: 'Resumen',
            ),
            const SizedBox(height: 14),
            _SummaryRow(label: 'Subtotal', value: '\$${cartState.subtotal.toStringAsFixed(0)}'),
            if (cartState.discountAmount > 0)
              _SummaryRow(
                label: 'Descuento',
                value: '-\$${cartState.discountAmount.toStringAsFixed(0)}',
                valueColor: colorScheme.tertiary,
              ),
            if (cartState.deliveryFee > 0)
              _SummaryRow(
                label: 'Domicilio',
                value: '\$${cartState.deliveryFee.toStringAsFixed(0)}',
              ),
            const Divider(),
            _SummaryRow(
              label: 'Total',
              value: '\$${cartState.total.toStringAsFixed(0)}',
              isTotal: true,
              valueColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    )
                : TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? colorScheme.onSurface,
                    )
                : TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
          ),
        ],
      ),
    );
  }
}
