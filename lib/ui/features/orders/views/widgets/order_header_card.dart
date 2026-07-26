import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../domain/models/order.dart';
import 'geocode_address_button.dart';

/// Tarjeta única de información del pedido: cliente, tipo de venta, tipo de
/// entrega, dirección y costo de domicilio. Diseño compacto premium para el
/// paso 1 del flujo de nuevo pedido.
class OrderHeaderCard extends ConsumerWidget {
  final TextEditingController addressController;
  final TextEditingController deliveryFeeController;
  final VoidCallback onCustomerTap;
  final VoidCallback onClearCustomer;
  final ValueChanged<SaleType> onSaleTypeChanged;
  final ValueChanged<DeliveryType> onDeliveryTypeChanged;

  const OrderHeaderCard({
    super.key,
    required this.addressController,
    required this.deliveryFeeController,
    required this.onCustomerTap,
    required this.onClearCustomer,
    required this.onSaleTypeChanged,
    required this.onDeliveryTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(currentOrderCartProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isOccasional = cartState.isOccasionalCustomer;
    final isDelivery = cartState.deliveryType == DeliveryType.delivery;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Detalles del pedido',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CustomerSelector(
              customerName: cartState.customerName,
              isOccasional: isOccasional,
              onTap: onCustomerTap,
              onClear: onClearCustomer,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SaleTypeSelector(
                    value: cartState.saleType,
                    enabled: !isOccasional,
                    onChanged: onSaleTypeChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DeliveryTypeSelector(
                    value: cartState.deliveryType,
                    onChanged: onDeliveryTypeChanged,
                  ),
                ),
              ],
            ),
            if (isDelivery) ...[
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
          ],
        ),
      ),
    );
  }
}

class _CustomerSelector extends StatelessWidget {
  final String? customerName;
  final bool isOccasional;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _CustomerSelector({
    required this.customerName,
    required this.isOccasional,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              child: Icon(
                isOccasional ? Icons.person_outline : Icons.person,
                color: colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOccasional ? 'Cliente ocasional' : 'Cliente',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOccasional
                        ? 'Toque para buscar cliente'
                        : (customerName ?? 'Cliente'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isOccasional)
              IconButton(
                icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                onPressed: onClear,
                tooltip: 'Quitar cliente',
                visualDensity: VisualDensity.compact,
              ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleTypeSelector extends StatelessWidget {
  final SaleType value;
  final bool enabled;
  final ValueChanged<SaleType> onChanged;

  const _SaleTypeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCredit = value == SaleType.credit;

    return SegmentedButton<SaleType>(
      segments: SaleType.values
          .map(
            (type) => ButtonSegment(
              value: type,
              label: Text(type.label),
              icon: Icon(
                type == SaleType.cash ? Icons.payments_outlined : Icons.credit_card,
                size: 16,
              ),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: enabled
          ? (selected) {
              if (selected.isNotEmpty) onChanged(selected.first);
            }
          : null,
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedBackgroundColor:
            isCredit ? colorScheme.tertiaryContainer : colorScheme.primaryContainer,
        selectedForegroundColor:
            isCredit ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _DeliveryTypeSelector extends StatelessWidget {
  final DeliveryType value;
  final ValueChanged<DeliveryType> onChanged;

  const _DeliveryTypeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<DeliveryType>(
      segments: DeliveryType.values
          .map(
            (type) => ButtonSegment(
              value: type,
              label: Text(type.label),
              icon: Icon(
                type == DeliveryType.inStore
                    ? Icons.storefront_outlined
                    : Icons.delivery_dining_outlined,
                size: 16,
              ),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) onChanged(selected.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedBackgroundColor: value == DeliveryType.delivery
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer,
        selectedForegroundColor: value == DeliveryType.delivery
            ? colorScheme.onSecondaryContainer
            : colorScheme.onPrimaryContainer,
      ),
    );
  }
}
