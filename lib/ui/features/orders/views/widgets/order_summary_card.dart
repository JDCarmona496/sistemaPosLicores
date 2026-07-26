import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';

/// Resumen compacto del pedido: solo cantidad de ítems y total.
class OrderSummaryCard extends ConsumerWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            icon: Icons.shopping_bag_outlined,
            label: 'Ítems',
            value: '${cartState.itemCount}',
            color: colorScheme.primaryContainer,
            onColor: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _SummaryChip(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total',
            value: '\$${cartState.total.toStringAsFixed(0)}',
            color: colorScheme.primary,
            onColor: colorScheme.onPrimary,
            isLarge: true,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color onColor;
  final bool isLarge;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: isLarge ? 22 : 18, color: onColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: onColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: onColor,
                        fontSize: isLarge ? 18 : 14,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
