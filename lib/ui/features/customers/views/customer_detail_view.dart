import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/customer_providers.dart';
import '../../../../domain/models/customer.dart';

class CustomerDetailView extends ConsumerWidget {
  final String customerId;

  const CustomerDetailView({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final statsAsync = ref.watch(customerStatsProvider(customerId));
    final basketsAsync = ref.watch(customerBasketsProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => customerAsync.whenOrNull(
              data: (customer) {
                if (customer != null) {
                  context.push('/customers/edit/${customer.id}').then((result) {
                    if (result == true && context.mounted) {
                      ref.invalidate(customerByIdProvider(customerId));
                    }
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) => customer == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Cliente no encontrado'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              )
            : _buildCustomerDetail(context, ref, customer, statsAsync, basketsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(customerByIdProvider(customerId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetail(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
    AsyncValue<Map<String, dynamic>> statsAsync,
    AsyncValue<List> basketsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _getStatusColor(customer.status),
                    child: Text(
                      customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTypeChip(customer.customerType),
                            const SizedBox(width: 8),
                            _buildStatusChip(customer.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de Contacto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (customer.identification != null)
                    _buildInfoRow('Identificación', customer.identification!, Icons.badge),
                  _buildInfoRow('Teléfono', customer.phone, Icons.phone),
                  if (customer.email != null)
                    _buildInfoRow('Email', customer.email!, Icons.email),
                  if (customer.address != null)
                    _buildInfoRow('Dirección', customer.address!, Icons.location_on),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (customer.customerType == CustomerType.credit) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de Crédito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCreditInfo('Límite', customer.creditLimit, Colors.blue),
                        _buildCreditInfo('Saldo', customer.currentBalance, Colors.red),
                        _buildCreditInfo(
                          'Disponible',
                          customer.creditLimit - customer.currentBalance,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: customer.creditLimit > 0
                          ? (customer.currentBalance / customer.creditLimit).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: customer.currentBalance > customer.creditLimit * 0.8
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (customer.notes != null && customer.notes!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(customer.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          basketsAsync.when(
            data: (baskets) => baskets.isNotEmpty ? _buildBasketsCard(baskets) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Pedidos',
                  '${stats['total_orders'] ?? 0}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Gastado',
                  '\$${(stats['total_spent'] as num? ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatItem(
                  'Pendientes',
                  '${stats['pending_orders'] ?? 0}',
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBasketsCard(List baskets) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Canastas Retornables',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${baskets.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...baskets.take(3).map((basket) => ListTile(
                  leading: const Icon(Icons.shopping_basket, color: Colors.orange),
                  title: Text('Canasta #${basket.id.substring(0, 8)}'),
                  subtitle: Text('Estado: ${basket.status}'),
                  trailing: Text('${basket.quantityOut} unidades'),
                )),
            if (baskets.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Navegar a vista completa de canastas
                },
                child: const Text('Ver todas'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(CustomerType type) {
    Color color;
    String label;

    switch (type) {
      case CustomerType.occasional:
        color = Colors.grey;
        label = 'Ocasional';
        break;
      case CustomerType.frequent:
        color = Colors.blue;
        label = 'Frecuente';
        break;
      case CustomerType.wholesale:
        color = Colors.purple;
        label = 'Mayorista';
        break;
      case CustomerType.credit:
        color = Colors.orange;
        label = 'Crédito';
        break;
      case CustomerType.consignment:
        color = Colors.teal;
        label = 'Consignación';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(CustomerStatus status) {
    Color color;
    String label;

    switch (status) {
      case CustomerStatus.active:
        color = Colors.green;
        label = 'Activo';
        break;
      case CustomerStatus.inactive:
        color = Colors.grey;
        label = 'Inactivo';
        break;
      case CustomerStatus.blocked:
        color = Colors.red;
        label = 'Bloqueado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return Colors.green;
      case CustomerStatus.inactive:
        return Colors.grey;
      case CustomerStatus.blocked:
        return Colors.red;
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este cliente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(customersProvider.notifier).deleteCustomer(customerId);
                if (context.mounted) {
                  context.pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
