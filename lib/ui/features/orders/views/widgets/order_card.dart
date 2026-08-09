import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/payment_providers.dart';
import '../../../../../data/providers/printer_provider.dart';
import '../../../../../domain/models/order.dart';

/// Tarjeta de pedido reutilizable: se usa en la lista plana y
/// dentro de las tarjetas de agrupacion por zona.
class OrderCard extends ConsumerWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Cliente ocasional',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    order.customerPhone ?? 'Sin teléfono',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (order.deliveryType == DeliveryType.delivery &&
                  order.deliveryAddress != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    icon: _getSaleTypeIcon(order.saleType),
                    label: order.saleType.label,
                    color: order.saleType == SaleType.credit
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _buildInfoChip(
                    icon: _getDeliveryTypeIcon(order.deliveryType),
                    label: order.deliveryType.label,
                    color: Colors.blue,
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printReceipt(context, ref),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Re-imprimir'),
                    ),
                  ),
                  if (order.status != OrderStatus.cancelled &&
                      order.status != OrderStatus.returned) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/orders/edit/${order.id}'),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final itemsAsync = ref.read(orderItemsProvider(order.id));
    final items = itemsAsync.valueOrNull ?? [];
    final paymentsAsync = ref.read(paymentsByOrderProvider(order.id));
    final payments = paymentsAsync.valueOrNull ?? [];

    final result = await ref.read(printOrderReceiptProvider)(
      order,
      items,
      payments: payments,
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Recibo enviado a imprimir'
              : 'Error al imprimir: ${result.message}',
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  static Widget _buildStatusChip(OrderStatus status) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color.shade700,
        ),
      ),
    );
  }

  static Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static MaterialColor getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.inTransit:
        return Colors.indigo;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.partiallyDelivered:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.brown;
    }
  }

  static IconData _getSaleTypeIcon(SaleType type) {
    switch (type) {
      case SaleType.cash:
        return Icons.payments;
      case SaleType.credit:
        return Icons.account_balance_wallet;
    }
  }

  static IconData _getDeliveryTypeIcon(DeliveryType type) {
    switch (type) {
      case DeliveryType.inStore:
        return Icons.storefront;
      case DeliveryType.delivery:
        return Icons.delivery_dining;
    }
  }
}
