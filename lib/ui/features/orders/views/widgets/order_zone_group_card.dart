import 'package:flutter/material.dart';

import '../../../../../domain/services/order_zone_grouper.dart';
import 'order_card.dart';

/// Tarjeta expandible de una zona de entrega: muestra los pedidos
/// cercanos que pueden compartir un mismo viaje.
class OrderZoneGroupCard extends StatelessWidget {
  final OrderZone zone;
  final MaterialColor accentColor;

  const OrderZoneGroupCard({
    super.key,
    required this.zone,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canCombine = zone.orderCount > 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: accentColor.shade100,
          child: Icon(Icons.route, color: accentColor.shade700),
        ),
        title: Row(
          children: [
            Text(
              'Zona ${zone.zoneNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${zone.orderCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    zone.referenceAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (canCombine) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_gas_station,
                        size: 14, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Combina ${zone.orderCount} entregas en 1 viaje',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '\$${zone.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        children: [
          const SizedBox(height: 8),
          ...zone.orders.map((order) => OrderCard(order: order)),
        ],
      ),
    );
  }
}
