import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/order_providers.dart';
import '../../../../data/providers/payment_providers.dart';
import '../../../../data/providers/printer_provider.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/models/payment.dart';
import '../../../../domain/models/user.dart';

class OrderDetailView extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailView({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        actions: [
          orderAsync.when(
            data: (order) => order != null
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, order),
                    itemBuilder: (context) => _buildMenuItems(order),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Productos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
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
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: orderAsync.when(
        data: (order) => order != null ? _buildBottomBar(order) : const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(Order order) {
    final items = <PopupMenuItem<String>>[];

    if (_canAssignDelivery(order)) {
      items.add(
        const PopupMenuItem(
          value: 'assign_delivery',
          child: Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Asignar domiciliario'),
            ],
          ),
        ),
      );
    }

    if (_canMarkDelivery(order)) {
      items.add(
        const PopupMenuItem(
          value: 'mark_delivery',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Marcar entrega'),
            ],
          ),
        ),
      );
    }

    if (_canRegisterPayment(order)) {
      items.add(
        const PopupMenuItem(
          value: 'register_payment',
          child: Row(
            children: [
              Icon(Icons.payment, color: Colors.orange),
              SizedBox(width: 8),
              Text('Registrar pago'),
            ],
          ),
        ),
      );
    }

    if (_canCancel(order)) {
      items.add(
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancelar Pedido'),
            ],
          ),
        ),
      );
    }

    return items;
  }

  bool _canCancel(Order order) {
    return order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.partiallyDelivered;
  }

  bool _canAssignDelivery(Order order) {
    return order.deliveryType == DeliveryType.delivery &&
        order.deliveryPersonId == null &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready);
  }

  bool _canMarkDelivery(Order order) {
    return order.status == OrderStatus.inTransit ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.partiallyDelivered;
  }

  bool _canRegisterPayment(Order order) {
    return order.saleType == SaleType.credit &&
        order.status != OrderStatus.cancelled;
  }

  void _handleMenuAction(String action, Order order) async {
    switch (action) {
      case 'cancel':
        await _cancelOrder(order);
        break;
      case 'assign_delivery':
        await _assignDeliveryPerson(order);
        break;
      case 'mark_delivery':
        await _markDelivery(order);
        break;
      case 'register_payment':
        await _registerPayment(order);
        break;
    }
  }

  Future<void> _assignDeliveryPerson(Order order) async {
    final selected = await showDialog<User?>(
      context: context,
      builder: (context) => const _DeliveryPersonSelectorDialog(),
    );

    if (selected == null || !mounted) return;

    try {
      await ref.read(ordersProvider.notifier).assignDeliveryPerson(
            orderId: order.id,
            deliveryPersonId: selected.id,
          );
      ref.invalidate(orderByIdProvider(order.id));
      ref.invalidate(ordersProvider);
      _showSnack('Domiciliario asignado');
    } catch (e) {
      _showSnack('Error al asignar: $e', isError: true);
    }
  }

  Future<void> _markDelivery(Order order) async {
    final itemsAsync = ref.read(orderItemsProvider(order.id));
    final items = itemsAsync.valueOrNull ?? [];

    final result = await showDialog<List<({String orderItemId, int quantityDelivered})>?>(
      context: context,
      builder: (context) => _DeliveryItemsDialog(items: items),
    );

    if (result == null || result.isEmpty || !mounted) return;

    try {
      await ref.read(ordersProvider.notifier).markItemsDelivered(
            orderId: order.id,
            items: result,
          );
      ref.invalidate(orderByIdProvider(order.id));
      ref.invalidate(orderItemsProvider(order.id));
      ref.invalidate(ordersProvider);
      _showSnack('Entrega registrada');
    } catch (e) {
      _showSnack('Error al registrar entrega: $e', isError: true);
    }
  }

  Future<void> _registerPayment(Order order) async {
    final result = await showDialog<Payment?>(
      context: context,
      builder: (context) => _PaymentDialog(
        order: order,
        receivedBy: _currentUserId,
      ),
    );

    if (result == null || !mounted) return;

    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.create(
        orderId: order.id,
        customerId: order.customerId,
        paymentMethod: result.paymentMethod,
        amount: result.amount,
        reference: result.reference,
        receivedBy: _currentUserId ?? order.sellerId,
        notes: result.notes,
      );
      ref.invalidate(paymentsByOrderProvider(order.id));
      ref.invalidate(orderByIdProvider(order.id));
      _showSnack('Pago registrado');
    } catch (e) {
      _showSnack('Error al registrar pago: $e', isError: true);
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona el motivo de la cancelación:'),
            const SizedBox(height: 16),
            ...[
              'Cliente canceló',
              'Producto agotado',
              'Error en el pedido',
              'Cliente no disponible',
              'Otro',
            ].map((reason) => ListTile(
                  title: Text(reason),
                  onTap: () => Navigator.pop(context, reason),
                )),
          ],
        ),
      ),
    );

    if (reason == null || !mounted) return;

    try {
      await ref.read(ordersProvider.notifier).cancelOrder(
            id: order.id,
            reason: reason,
            cancelledBy: _currentUserId ?? order.sellerId,
          );
      ref.invalidate(orderByIdProvider(order.id));
      ref.invalidate(orderItemsProvider(order.id));
      ref.invalidate(ordersProvider);
      _showSnack('Pedido cancelado');
    } catch (e) {
      _showSnack('Error al cancelar: $e', isError: true);
    }
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
          Row(
            children: [
              _buildInfoChip(
                icon: _getSaleTypeIcon(order.saleType),
                label: order.saleType.label,
                color: order.saleType == SaleType.credit
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: _getDeliveryTypeIcon(order.deliveryType),
                label: order.deliveryType.label,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.notes != null && order.notes!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  Text(
                    '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} x \$${item.unitPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.discountAmount > 0)
                  Text(
                    '-\$${item.discountAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                if (item.isWholesalePrice)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Mayorista',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Order order) {
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text('\$${order.subtotal.toStringAsFixed(0)}'),
                ],
              ),
              if (order.discountAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Descuento:',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '-\$${order.discountAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ],
                ),
              if (order.deliveryFee > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Domicilio:',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text('\$${order.deliveryFee.toStringAsFixed(0)}'),
                  ],
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (order.saleType == SaleType.credit)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showPayments(order),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Ver pagos / abonos'),
                  ),
                ),
              if (order.saleType == SaleType.credit)
                const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _printReceipt(order),
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir recibo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPayments(Order order) async {
    await showDialog(
      context: context,
      builder: (context) => _PaymentsDialog(orderId: order.id),
    );
  }

  Future<void> _printReceipt(Order order) async {
    final itemsAsync = ref.read(orderItemsProvider(order.id));
    final items = itemsAsync.valueOrNull ?? [];

    final result = await ref.read(printOrderReceiptProvider)(order, items);

    if (!mounted) return;
    _showSnack(
      result.success ? result.message : result.message,
      isError: !result.success,
    );
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

  Widget _buildInfoChip({
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

  MaterialColor _getStatusColor(OrderStatus status) {
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
        return Colors.green;
      case OrderStatus.partiallyDelivered:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.brown;
    }
  }

  IconData _getSaleTypeIcon(SaleType type) {
    switch (type) {
      case SaleType.cash:
        return Icons.payments;
      case SaleType.credit:
        return Icons.account_balance_wallet;
    }
  }

  IconData _getDeliveryTypeIcon(DeliveryType type) {
    switch (type) {
      case DeliveryType.inStore:
        return Icons.storefront;
      case DeliveryType.delivery:
        return Icons.delivery_dining;
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
}

class _DeliveryPersonSelectorDialog extends ConsumerWidget {
  const _DeliveryPersonSelectorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(deliveryUsersProvider);

    return AlertDialog(
      title: const Text('Asignar domiciliario'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: usersAsync.when(
          data: (users) => users.isEmpty
              ? const Center(child: Text('No hay domiciliarios activos'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.fullName[0].toUpperCase()),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _DeliveryItemsDialog extends StatefulWidget {
  final List<OrderItem> items;

  const _DeliveryItemsDialog({required this.items});

  @override
  State<_DeliveryItemsDialog> createState() => _DeliveryItemsDialogState();
}

class _DeliveryItemsDialogState extends State<_DeliveryItemsDialog> {
  late final Map<String, int> _deliveredQuantities;

  @override
  void initState() {
    super.initState();
    _deliveredQuantities = {
      for (final item in widget.items)
        item.id: item.quantityDelivered,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar entrega'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final pending = item.quantity - item.quantityDelivered;
            return ListTile(
              title: Text(item.productName ?? 'Producto'),
              subtitle: Text('Pendiente: $pending'),
              trailing: SizedBox(
                width: 80,
                child: TextField(
                  controller: TextEditingController(
                    text: '${_deliveredQuantities[item.id]}',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    _deliveredQuantities[item.id] =
                        int.tryParse(value) ?? 0;
                  },
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = <({String orderItemId, int quantityDelivered})>[];
            for (final item in widget.items) {
              final delivered = _deliveredQuantities[item.id] ?? 0;
              if (delivered > item.quantityDelivered) {
                result.add((
                  orderItemId: item.id,
                  quantityDelivered: delivered,
                ));
              }
            }
            Navigator.pop(context, result);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PaymentsDialog extends ConsumerWidget {
  final String orderId;

  const _PaymentsDialog({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByOrderProvider(orderId));

    return AlertDialog(
      title: const Text('Pagos / Abonos'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const Center(child: Text('No hay pagos registrados'));
            }
            return ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text('${payment.paymentMethod.label} - \$${payment.amount.toStringAsFixed(0)}'),
                  subtitle: Text(payment.createdAt != null
                      ? payment.createdAt!.toLocal().toString().substring(0, 16)
                      : ''),
                  trailing: payment.reference != null
                      ? Text(payment.reference!, style: const TextStyle(fontSize: 12))
                      : null,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Order order;
  final String? receivedBy;

  const _PaymentDialog({required this.order, this.receivedBy});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total pedido: \$${widget.order.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Referencia (opcional)',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (amount <= 0) return;
            Navigator.pop(
              context,
              Payment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                orderId: widget.order.id,
                customerId: widget.order.customerId,
                paymentMethod: _method,
                amount: amount,
                reference: _referenceController.text.isEmpty
                    ? null
                    : _referenceController.text,
                receivedBy: widget.receivedBy ?? '',
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              ),
            );
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
