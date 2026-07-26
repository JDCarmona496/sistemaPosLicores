import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import 'cart_item_card.dart';
import 'notes_section.dart';
import 'order_summary_section.dart';
import 'section_header.dart';

/// Panel del carrito: lista de ítems, notas y resumen.
class OrderCartPanel extends ConsumerWidget {
  final TextEditingController notesController;

  const OrderCartPanel({
    super.key,
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
