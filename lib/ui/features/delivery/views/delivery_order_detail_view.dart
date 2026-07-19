import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/providers/order_providers.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import 'widgets/delivery_signature_dialog.dart';

class DeliveryOrderDetailView extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryOrderDetailView({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryOrderDetailView> createState() =>
      _DeliveryOrderDetailViewState();
}

class _DeliveryOrderDetailViewState
    extends ConsumerState<DeliveryOrderDetailView> {
  /// Cantidad total entregada por ítem (editable en pantalla).
  final Map<String, int> _deliveredQuantities = {};
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    // Inicializar cantidades locales cuando llegan los items.
    itemsAsync.whenData((items) {
      if (_deliveredQuantities.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            for (final item in items) {
              _deliveredQuantities[item.id] = item.quantityDelivered;
            }
          });
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Entrega'),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pedido no encontrado'));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildOrderHeader(order),
              ),
              SliverToBoxAdapter(
                child: _buildCustomerInfo(order),
              ),
              if (order.notes != null && order.notes!.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildNotes(order),
                ),
              SliverToBoxAdapter(
                child: _buildProductsHeader(order, itemsAsync),
              ),
              itemsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
                data: (items) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildItemCard(items[index]),
                    childCount: items.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: orderAsync.when(
        data: (order) =>
            order != null ? _buildBottomBar(order, itemsAsync) : const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  bool _canDeliver(Order order) {
    return order.status == OrderStatus.inTransit ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.partiallyDelivered;
  }

  Widget _buildOrderHeader(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(order.status).shade50,
        border: Border(
          bottom: BorderSide(color: _getStatusColor(order.status).shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido #${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusChip(order.status),
            ],
          ),
          const SizedBox(height: 8),
          if (order.deliveryAddress != null)
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Order order) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName ?? 'Cliente ocasional',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (order.customerPhone != null)
                        Text(
                          order.customerPhone!,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      if (order.customerAddress != null)
                        Text(
                          order.customerAddress!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (order.customerPhone != null)
                  IconButton(
                    onPressed: () async {
                      final uri =
                          Uri(scheme: 'tel', path: order.customerPhone!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.note, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.notes!,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsHeader(
      Order order, AsyncValue<List<OrderItem>> itemsAsync) {
    final items = itemsAsync.valueOrNull ?? [];
    final canDeliver = _canDeliver(order);
    final hasPending = items.any((i) => i.pendingQuantity > 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos (${items.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (canDeliver && hasPending)
                TextButton.icon(
                  onPressed: _markAllDelivered,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Entregar todo'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ajusta la cantidad entregada de cada producto. Luego presiona el botón Entregar.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    final pending = item.quantity - item.quantityDelivered;
    final isFullyDelivered = pending == 0;
    final currentTotal = _deliveredQuantities[item.id] ?? item.quantityDelivered;
    final isValid = currentTotal >= item.quantityDelivered &&
        currentTotal <= item.quantity;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isFullyDelivered ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? 'Producto',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (item.productPresentation != null)
                    Text(
                      item.productPresentation!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Pedido: ${item.quantity}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Entregado: ${item.quantityDelivered}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFullyDelivered
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      if (!isFullyDelivered) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Pendiente: $pending',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isFullyDelivered)
              const Icon(Icons.check_circle, color: Colors.green)
            else
              SizedBox(
                width: 70,
                child: TextField(
                  controller: TextEditingController(
                    text: '$currentTotal',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    errorText: isValid ? null : '',
                  ),
                  onChanged: (value) {
                    final total = int.tryParse(value) ?? 0;
                    setState(() {
                      _deliveredQuantities[item.id] = total;
                      _validationError = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      Order order, AsyncValue<List<OrderItem>> itemsAsync) {
    final items = itemsAsync.valueOrNull ?? [];
    final canDeliver = _canDeliver(order);
    final itemsToDeliver = _buildItemsToDeliver(items);
    final hasDeliveries = itemsToDeliver.isNotEmpty;
    final allValid = items.every((item) {
      final total = _deliveredQuantities[item.id] ?? item.quantityDelivered;
      return total >= item.quantityDelivered && total <= item.quantity;
    });

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _validationError!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (canDeliver)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasDeliveries && allValid
                      ? () => _confirmDelivery(order, items)
                      : null,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    hasDeliveries
                        ? 'Entregar (${itemsToDeliver.length} cambios)'
                        : 'Sin cambios para entregar',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (!canDeliver && order.status == OrderStatus.delivered)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Pedido entregado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<({String orderItemId, int quantityDelivered})> _buildItemsToDeliver(
      List<OrderItem> items) {
    final result = <({String orderItemId, int quantityDelivered})>[];
    for (final item in items) {
      final total = _deliveredQuantities[item.id] ?? item.quantityDelivered;
      if (total > item.quantityDelivered && total <= item.quantity) {
        result.add((
          orderItemId: item.id,
          quantityDelivered: total,
        ));
      }
    }
    return result;
  }

  void _markAllDelivered() {
    setState(() {
      final itemsAsync = ref.read(orderItemsProvider(widget.orderId));
      final items = itemsAsync.valueOrNull ?? [];
      for (final item in items) {
        _deliveredQuantities[item.id] = item.quantity;
      }
      _validationError = null;
    });
  }

  Future<void> _confirmDelivery(Order order, List<OrderItem> items) async {
    final itemsToDeliver = _buildItemsToDeliver(items);
    if (itemsToDeliver.isEmpty) return;

    final allValid = items.every((item) {
      final total = _deliveredQuantities[item.id] ?? item.quantityDelivered;
      return total >= item.quantityDelivered && total <= item.quantity;
    });

    if (!allValid) {
      setState(() => _validationError =
          'Revisa las cantidades: no puedes entregar menos de lo ya entregado ni más de lo pedido.');
      return;
    }

    setState(() => _validationError = null);

    final result = await DeliverySignatureDialog.show(
      context,
      order: order,
      itemsToDeliver: itemsToDeliver,
    );

    if (result == true && mounted) {
      ref.invalidate(orderByIdProvider(order.id));
      ref.invalidate(orderItemsProvider(order.id));
      setState(() => _deliveredQuantities.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega registrada correctamente')),
      );
    }
  }

  Widget _buildStatusChip(OrderStatus status) {
    final color = _getStatusColor(status);
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

  MaterialColor _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.inTransit:
        return Colors.indigo;
      case OrderStatus.partiallyDelivered:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
