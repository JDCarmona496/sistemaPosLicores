import 'package:flutter/material.dart';

import '../../../../../domain/services/order_zone_grouper.dart';
import 'delivery_order_card.dart';
import 'package:geolocator/geolocator.dart';

/// Tarjeta expandible de una zona de entrega del domiciliario.
class DeliveryZoneGroupCard extends StatelessWidget {
  final OrderZone zone;
  final Position? currentPosition;
  final VoidCallback? onComplete;

  const DeliveryZoneGroupCard({
    super.key,
    required this.zone,
    this.currentPosition,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Icon(Icons.route, color: Colors.indigo.shade700),
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
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${zone.orderCount} pedidos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '\$${zone.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            if (zone.orderCount > 1) ...[
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
        children: [
          const SizedBox(height: 8),
          ...zone.orders.map((order) => DeliveryOrderCard(
                order: order,
                currentPosition: currentPosition,
                onComplete: onComplete,
              )),
        ],
      ),
    );
  }
}
