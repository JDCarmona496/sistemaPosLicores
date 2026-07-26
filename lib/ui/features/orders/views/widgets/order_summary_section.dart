import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import 'section_header.dart';

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
            _SummaryRow(
                label: 'Subtotal',
                value: '\$${cartState.subtotal.toStringAsFixed(0)}'),
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
