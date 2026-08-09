import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/order_edit_cart_provider.dart';
import '../../../../data/providers/order_providers.dart';
import '../../../../data/providers/product_providers.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import 'widgets/price_type_style.dart';
import 'widgets/product_selector_dialog.dart';
import 'widgets/quantity_selector.dart';

class OrderEditView extends ConsumerStatefulWidget {
  final String orderId;

  const OrderEditView({super.key, required this.orderId});

  @override
  ConsumerState<OrderEditView> createState() => _OrderEditViewState();
}

class _OrderEditViewState extends ConsumerState<OrderEditView> {
  bool _isSaving = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    ref.read(orderEditCartProvider.notifier).clear();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user.id);
      }
    } catch (e) {
      setState(() => _currentUserId = null);
    }
  }

  Future<void> _addProduct() async {
    final item = await showDialog<OrderItem?>(
      context: context,
      builder: (context) => const ProductSelectorDialog(),
    );

    if (item == null) return;

    ref.read(orderEditCartProvider.notifier).addItem(
          productId: item.productId,
          productName: item.productName ?? 'Producto',
          productPresentation: item.productPresentation,
          price: item.unitPrice,
          quantity: item.quantity,
          priceType: item.priceType,
        );
  }

  Future<void> _saveChanges(Order order) async {
    if (_currentUserId == null) {
      _showSnack('No se pudo identificar el usuario actual', isError: true);
      return;
    }

    final cartState = ref.read(orderEditCartProvider);
    if (cartState.items.isEmpty) {
      _showSnack(
        'El pedido debe tener al menos un producto. Elimina el pedido si ya no aplica.',
        isError: true,
      );
      return;
    }

    final confirmed = await _confirmEdit(order);
    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(orderRepositoryProvider);
      final current = cartState.items;
      final original = cartState.originalItems;

      // 1. Ítems eliminados.
      final removed = original
          .where((o) => !current.any((c) => c.id == o.id))
          .toList();

      // 2. Ítems existentes cuyo precio/tipo cambió: se eliminan y se agregan.
      final priceChanged = current.where((c) {
        final o = original.firstWhere(
          (o) => o.id == c.id,
          orElse: () => c,
        );
        return o.id == c.id &&
            (o.priceType != c.priceType || o.unitPrice != c.unitPrice);
      }).toList();

      // 3. Ítems existentes cuya cantidad cambió (sin cambio de precio).
      final quantityChanged = current.where((c) {
        final o = original.firstWhere(
          (o) => o.id == c.id,
          orElse: () => c,
        );
        return o.id == c.id &&
            o.priceType == c.priceType &&
            o.unitPrice == c.unitPrice &&
            o.quantity != c.quantity;
      }).toList();

      // 4. Ítems nuevos.
      final added = current
          .where((c) => !original.any((o) => o.id == c.id))
          .toList();

      // Ejecutar en orden: eliminaciones, cambios de precio (remove+add),
      // cambios de cantidad, adiciones.
      for (final item in removed) {
        await repository.removeOrderItem(
          orderId: order.id,
          orderItemId: item.id,
          editedBy: _currentUserId!,
          reason: 'Edición de pedido',
        );
      }

      for (final item in priceChanged) {
        final originalItem = original.firstWhere((o) => o.id == item.id);
        await repository.removeOrderItem(
          orderId: order.id,
          orderItemId: originalItem.id,
          editedBy: _currentUserId!,
          reason: 'Cambio de tipo de precio',
        );
        await repository.addOrderItem(
          orderId: order.id,
          item: item.copyWith(orderId: order.id),
          editedBy: _currentUserId!,
          reason: 'Cambio de tipo de precio',
        );
      }

      for (final item in quantityChanged) {
        await repository.editOrderItem(
          orderId: order.id,
          orderItemId: item.id,
          newQuantity: item.quantity,
          editedBy: _currentUserId!,
          reason: 'Cambio de cantidad',
        );
      }

      for (final item in added) {
        await repository.addOrderItem(
          orderId: order.id,
          item: item.copyWith(orderId: order.id),
          editedBy: _currentUserId!,
          reason: 'Producto agregado en edición',
        );
      }

      _showSnack('Pedido #${order.orderNumber} actualizado');

      ref.invalidate(orderByIdProvider(widget.orderId));
      ref.invalidate(orderItemsProvider(widget.orderId));
      ref.invalidate(ordersProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showSnack('Error al guardar cambios: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmEdit(Order order) async {
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.completed) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pedido entregado/completado'),
          content: const Text(
            'Este pedido ya fue entregado o pagado. Editarlo afectará stock y saldos. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      return result == true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));
    final cartState = ref.watch(orderEditCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar pedido'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pedido no encontrado'));
          }

          // Cargar items en el carrito de edición la primera vez.
          itemsAsync.whenData((items) {
            if (cartState.originalItems.isEmpty && cartState.items.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(orderEditCartProvider.notifier).load(items);
              });
            }
          });

          return Column(
            children: [
              _buildHeader(order),
              Expanded(
                child: cartState.items.isEmpty
                    ? const Center(
                        child: Text('No hay productos en el pedido'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartState.items.length,
                        itemBuilder: (context, index) {
                          final item = cartState.items[index];
                          return _buildItemCard(order, item);
                        },
                      ),
              ),
              _buildBottomBar(order, cartState),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error al cargar pedido: $error'),
        ),
      ),
    );
  }

  Widget _buildHeader(Order order) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text(
                    order.status.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _statusColor(order.status, colorScheme),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.customerName?.isNotEmpty == true
                  ? order.customerName!
                  : 'Cliente ocasional',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Order order, OrderItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final productAsync = ref.watch(productByIdProvider(item.productId));
    final maxQty = productAsync.when(
      data: (product) {
        if (product == null) return null;
        // Para ítems ya existentes, el stock disponible es el stock actual
        // más la cantidad que ya fue reservada por este ítem.
        final reserved = item.orderId == order.id ? item.quantity : 0;
        return (product.stockCurrent + reserved).toInt();
      },
      loading: () => null,
      error: (_, _) => null,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                  if (item.productPresentation?.isNotEmpty == true)
                    Text(
                      item.productPresentation!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  _ItemPriceTypeChip(item: item),
                ],
              ),
            ),
            QuantitySelector(
              quantity: item.quantity,
              maxQuantity: maxQty,
              onChanged: (qty) => ref
                  .read(orderEditCartProvider.notifier)
                  .updateItemQuantity(item.id, qty),
              onLimitExceeded: (message) => _showSnack(message, isError: true),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_formatMoney(item.subtotal)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () => ref
                      .read(orderEditCartProvider.notifier)
                      .removeItem(item.id),
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Order order, OrderEditCartState cartState) {
    final colorScheme = Theme.of(context).colorScheme;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '\$${_formatMoney(cartState.subtotal - cartState.discountAmount + order.deliveryFee)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar producto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving || _currentUserId == null
                        ? null
                        : () => _saveChanges(order),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status, ColorScheme colorScheme) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade100;
      case OrderStatus.preparing:
      case OrderStatus.inTransit:
        return Colors.blue.shade100;
      case OrderStatus.ready:
        return Colors.purple.shade100;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Colors.green.shade100;
      case OrderStatus.partiallyDelivered:
        return Colors.amber.shade100;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return Colors.red.shade100;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }
}

class _ItemPriceTypeChip extends ConsumerWidget {
  final OrderItem item;

  const _ItemPriceTypeChip({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.priceType.color;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPriceTypeSelector(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.priceType.icon, size: 12, color: color.shade700),
            const SizedBox(width: 4),
            Text(
              item.priceType.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.edit, size: 10, color: color.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _showPriceTypeSelector(BuildContext context, WidgetRef ref) async {
    final selected = await showDialog<OrderItemPriceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar tipo de precio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderItemPriceType.values.map((type) {
            final selected = type == item.priceType;
            return ListTile(
              leading: Icon(type.icon, color: type.color.shade700),
              title: Text(type.label),
              trailing: selected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, type),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null && selected != item.priceType) {
      ref
          .read(orderEditCartProvider.notifier)
          .updateItemPriceType(item.id, selected);
    }
  }
}
