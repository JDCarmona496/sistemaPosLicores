import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';

/// Barra inferior fija con resumen de totales y botón de crear pedido.
class BottomCheckoutBar extends ConsumerWidget {
  final bool isLoading;
  final bool canSave;
  final VoidCallback onSave;

  const BottomCheckoutBar({
    super.key,
    required this.isLoading,
    required this.canSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final hasItems = cartState.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBreakdown(context, cartState),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading || !canSave || !hasItems ? null : onSave,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                !canSave
                    ? 'CARGANDO USUARIO...'
                    : 'CREAR PEDIDO \u00b7 \$${cartState.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(BuildContext context, CurrentOrderCartState cartState) {
    final colorScheme = Theme.of(context).colorScheme;
    final breakdown = <Widget>[
      _BreakdownRow(
        label: 'Subtotal',
        value: '\$${cartState.subtotal.toStringAsFixed(0)}',
        color: colorScheme.onSurface,
      ),
    ];

    if (cartState.discountAmount > 0) {
      breakdown.add(_BreakdownRow(
        label: 'Descuento',
        value: '-\$${cartState.discountAmount.toStringAsFixed(0)}',
        color: colorScheme.tertiary,
      ));
    }

    if (cartState.deliveryFee > 0) {
      breakdown.add(_BreakdownRow(
        label: 'Domicilio',
        value: '\$${cartState.deliveryFee.toStringAsFixed(0)}',
        color: colorScheme.onSurface,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...breakdown,
        const Divider(),
        _BreakdownRow(
          label: 'Total',
          value: '\$${cartState.total.toStringAsFixed(0)}',
          color: colorScheme.primary,
          isTotal: true,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isTotal;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )
                : TextStyle(color: color.withValues(alpha: 0.8)),
          ),
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )
                : TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
          ),
        ],
      ),
    );
  }
}
