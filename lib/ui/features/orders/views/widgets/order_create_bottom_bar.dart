import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';

/// Barra inferior con el resumen de totales y el botón de crear pedido.
class OrderCreateBottomBar extends ConsumerWidget {
  final bool isLoading;
  final bool canSave;
  final VoidCallback onSave;

  const OrderCreateBottomBar({
    super.key,
    required this.isLoading,
    required this.canSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cartState.items.length} productos',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Subtotal: \$${cartState.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
            if (cartState.discountAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Descuento: -\$${cartState.discountAmount.toStringAsFixed(0)}',
                    style: TextStyle(color: colorScheme.tertiary),
                  ),
                ],
              ),
            if (cartState.deliveryFee > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Domicilio: \$${cartState.deliveryFee.toStringAsFixed(0)}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
            Divider(color: colorScheme.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${cartState.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading || !canSave ? null : onSave,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: !canSave
                    ? const Text('CARGANDO USUARIO...')
                    : const Text('CREAR PEDIDO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
