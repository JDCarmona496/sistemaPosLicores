import 'package:flutter/material.dart';

import '../../../../../domain/models/order_item.dart';
import 'price_type_style.dart';

/// Selector de tipo de precio por defecto con Material SegmentedButton.
class PriceTypeSelector extends StatelessWidget {
  final OrderItemPriceType value;
  final ValueChanged<OrderItemPriceType> onChanged;

  const PriceTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<OrderItemPriceType>(
      segments: OrderItemPriceType.values
          .map(
            (type) => ButtonSegment(
              value: type,
              icon: Icon(type.icon, size: 16),
              label: Text(type.label),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) onChanged(selected.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedBackgroundColor: value.color.withValues(alpha: 0.2),
        selectedForegroundColor: value.color.shade800,
      ),
    );
  }
}
