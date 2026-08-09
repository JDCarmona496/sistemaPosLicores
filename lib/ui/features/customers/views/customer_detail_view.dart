import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/customer_providers.dart';
import '../../../../domain/models/customer.dart';

class CustomerDetailView extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailView({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends ConsumerState<CustomerDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    final statsAsync = ref.watch(customerStatsProvider(widget.customerId));

    return Scaffold(
      body: customerAsync.when(
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
        data: (customer) {
          if (customer == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Cliente no encontrado'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        context.push('/customers/edit/${customer.id}'),
                    tooltip: 'Editar',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(value, customer),
                    itemBuilder: (context) => [
                      if (customer.status == CustomerStatus.active)
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Desactivar'),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Activar'),
                            ],
                          ),
                        ),
                      if (customer.status != CustomerStatus.blocked)
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Bloquear'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    customer.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: _buildHeader(customer, statsAsync),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.info), text: 'Información'),
                    Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
                    Tab(icon: Icon(Icons.inventory_2), text: 'Canastas'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(customer),
                _buildOrdersTab(widget.customerId),
                _buildBasketsTab(widget.customerId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    Customer customer,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getTypeColor(customer.type).shade400,
            _getTypeColor(customer.type).shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _getTypeIcon(customer.type),
                      size: 32,
                      color: _getTypeColor(customer.type).shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.type.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Información de Contacto',
            Icons.contact_phone,
            [
              _buildInfoRow('Teléfono', customer.phone, copyable: true),
              if (customer.email != null)
                _buildInfoRow('Email', customer.email!, copyable: true),
              if (customer.identification != null)
                _buildInfoRow('Identificación', customer.identification!,
                    copyable: true),
            ],
          ),
          const SizedBox(height: 16),
          if (customer.address != null)
            _buildSection(
              'Dirección',
              Icons.location_on,
              [
                _buildInfoRow('Dirección', customer.address!),
                if (customer.latitude != null && customer.longitude != null)
                  _buildInfoRow(
                    'Coordenadas',
                    '${customer.latitude!.toStringAsFixed(6)}, ${customer.longitude!.toStringAsFixed(6)}',
                  ),
              ],
            ),
          if (customer.address != null) const SizedBox(height: 16),
          _buildSection(
            'Información Comercial',
            Icons.business_center,
            [
              _buildInfoRow('Tipo de Cliente', customer.type.label),
              _buildInfoRow('Estado', customer.status.label),
              _buildInfoRow('Cupo de Crédito',
                  '\$${customer.creditLimit.toStringAsFixed(0)}'),
              if (customer.type == CustomerType.credit)
                _buildInfoRow(
                  'Saldo Actual',
                  '\$${customer.currentBalance.toStringAsFixed(0)}',
                  valueColor: customer.currentBalance > 0
                      ? Colors.red
                      : Colors.green,
                ),
            ],
          ),
          if (customer.notes != null && customer.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              'Notas',
              Icons.note,
              [
                Text(
                  customer.notes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildSection(
            'Información del Sistema',
            Icons.info_outline,
            [
              if (customer.createdAt != null)
                _buildInfoRow(
                  'Creado',
                  _formatDate(customer.createdAt!),
                ),
              if (customer.updatedAt != null)
                _buildInfoRow(
                  'Actualizado',
                  _formatDate(customer.updatedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(String customerId) {
    final ordersAsync = ref.watch(customerOrdersHistoryProvider(customerId));

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Sin pedidos',
                  style: TextStyle(
                      fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getOrderStatusColor(order['status']),
                  child: Icon(
                    _getOrderStatusIcon(order['status']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Pedido #${order['order_number']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatOrderStatus(order['status'])),
                    Text(
                      _formatDate(DateTime.parse(order['created_at'])),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '\$${(order['total'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBasketsTab(String customerId) {
    final basketsAsync = ref.watch(customerBasketsProvider(customerId));
    final statsAsync = ref.watch(customerBasketStatsProvider(customerId));

    return Column(
      children: [
        statsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (stats) => Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Salidas',
                  '${stats['total_out'] ?? 0}',
                  Icons.outbox,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Devueltas',
                  '${stats['total_returned'] ?? 0}',
                  Icons.inbox,
                  Colors.green,
                ),
                _buildStatItem(
                  'Pendientes',
                  '${stats['total_pending'] ?? 0}',
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Depósito',
                  '\$${(stats['total_deposit'] ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: basketsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (baskets) {
              if (baskets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Sin canastas',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: baskets.length,
                itemBuilder: (context, index) {
                  final basket = baskets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getBasketStatusColor(basket.status),
                        child: Icon(
                          _getBasketStatusIcon(basket.status),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Canasta #${basket.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${basket.quantityReturned}/${basket.quantityOut} devueltas',
                          ),
                          if (basket.depositAmount > 0)
                            Text(
                              'Depósito: \$${basket.depositAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getBasketStatusColor(basket.status).shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getBasketStatusLabel(basket.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                _getBasketStatusColor(basket.status).shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool copyable = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copiado al portapapeles'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, MaterialColor color) {
    return Column(
      children: [
        Icon(icon, color: color.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Customer customer) async {
    switch (action) {
      case 'activate':
        await ref
            .read(customersProvider.notifier)
            .updateStatus(customer.id, CustomerStatus.active);
        _invalidateCustomerProviders(customer.id);
        _showSnack('Cliente activado');
        break;
      case 'deactivate':
        await ref
            .read(customersProvider.notifier)
            .updateStatus(customer.id, CustomerStatus.inactive);
        _invalidateCustomerProviders(customer.id);
        _showSnack('Cliente desactivado');
        break;
      case 'block':
        await ref
            .read(customersProvider.notifier)
            .updateStatus(customer.id, CustomerStatus.blocked);
        _invalidateCustomerProviders(customer.id);
        _showSnack('Cliente bloqueado');
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Cliente'),
            content: Text(
                '¿Estás seguro de eliminar a ${customer.fullName}? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await ref
                .read(customersProvider.notifier)
                .deleteCustomer(customer.id);
            _invalidateCustomerProviders(customer.id);
            if (mounted) context.pop();
            _showSnack('Cliente eliminado');
          } catch (e) {
            _showSnack('Error al eliminar: $e', isError: true);
          }
        }
        break;
    }
  }

  void _invalidateCustomerProviders(String customerId) {
    ref.invalidate(customerByIdProvider(customerId));
    ref.invalidate(customerStatsProvider(customerId));
    ref.invalidate(customerBasketsProvider(customerId));
    ref.invalidate(customerBasketStatsProvider(customerId));
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

  MaterialColor _getTypeColor(CustomerType type) {
    switch (type) {
      case CustomerType.occasional:
        return Colors.grey;
      case CustomerType.frequent:
        return Colors.blue;
      case CustomerType.wholesale:
        return Colors.purple;
      case CustomerType.credit:
        return Colors.orange;
      case CustomerType.consignment:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(CustomerType type) {
    switch (type) {
      case CustomerType.occasional:
        return Icons.person;
      case CustomerType.frequent:
        return Icons.person_outline;
      case CustomerType.wholesale:
        return Icons.business;
      case CustomerType.credit:
        return Icons.account_balance_wallet;
      case CustomerType.consignment:
        return Icons.inventory;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'preparing':
        return 'Preparando';
      case 'in_route':
        return 'En ruta';
      case 'delivered':
        return 'Entregado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  MaterialColor _getBasketStatusColor(String status) {
    switch (status) {
      case 'outstanding':
        return Colors.orange;
      case 'returned':
        return Colors.green;
      case 'charged':
        return Colors.red;
      case 'deposit_held':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getBasketStatusIcon(String status) {
    switch (status) {
      case 'outstanding':
        return Icons.outbox;
      case 'returned':
        return Icons.inbox;
      case 'charged':
        return Icons.attach_money;
      case 'deposit_held':
        return Icons.savings;
      default:
        return Icons.help_outline;
    }
  }

  String _getBasketStatusLabel(String status) {
    switch (status) {
      case 'outstanding':
        return 'Pendiente';
      case 'returned':
        return 'Devuelta';
      case 'charged':
        return 'Cobrada';
      case 'deposit_held':
        return 'Depósito';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
