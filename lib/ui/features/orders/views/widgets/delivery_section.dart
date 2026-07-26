import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import 'geocode_address_button.dart';
import 'section_header.dart';

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
