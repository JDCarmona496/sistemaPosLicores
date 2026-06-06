import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/customer_providers.dart';
import '../../../../domain/models/customer.dart';

class CustomersView extends ConsumerStatefulWidget {
  const CustomersView({super.key});

  @override
  ConsumerState<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends ConsumerState<CustomersView> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono o identificación...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customersProvider.notifier).setSearch(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(customersProvider.notifier).setSearch(value.isEmpty ? null : value);
              },
            ),
          ),
          if (_showFilters) _buildFilters(customersState),
          Expanded(
            child: _buildCustomersList(customersState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(CustomersState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: state.selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    DropdownMenuItem<String?>(value: 'occasional', child: Text('Ocasional')),
                    DropdownMenuItem<String?>(value: 'frequent', child: Text('Frecuente')),
                    DropdownMenuItem<String?>(value: 'wholesale', child: Text('Mayorista')),
                    DropdownMenuItem<String?>(value: 'credit', child: Text('Crédito')),
                    DropdownMenuItem<String?>(value: 'consignment', child: Text('Consignación')),
                  ],
                  onChanged: (value) {
                    ref.read(customersProvider.notifier).setType(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: state.selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    DropdownMenuItem<String?>(value: 'active', child: Text('Activo')),
                    DropdownMenuItem<String?>(value: 'inactive', child: Text('Inactivo')),
                    DropdownMenuItem<String?>(value: 'blocked', child: Text('Bloqueado')),
                  ],
                  onChanged: (value) {
                    ref.read(customersProvider.notifier).setStatus(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.selectedType != null || state.selectedStatus != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(customersProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomersList(CustomersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(customersProvider.notifier).loadCustomers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay clientes',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              state.searchQuery != null || state.selectedType != null || state.selectedStatus != null
                  ? 'No se encontraron clientes con los filtros aplicados'
                  : 'Agrega tu primer cliente',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            if (state.searchQuery != null || state.selectedType != null || state.selectedStatus != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(customersProvider.notifier).clearFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customersProvider.notifier).loadCustomers(),
      child: ListView.builder(
        itemCount: state.customers.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final customer = state.customers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getStatusColor(customer.status),
                child: Text(
                  customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
              if (customer.currentBalance > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '\$${customer.currentBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
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
}
