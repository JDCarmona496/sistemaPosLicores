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
            icon: Icon(_showFilters
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
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
                hintText: 'Buscar por nombre, cédula o teléfono...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(customersProvider.notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(customersProvider.notifier)
                    .setSearch(value.isEmpty ? null : value);
              },
            ),
          ),
          if (_showFilters) _buildFilters(customersState),
          Expanded(
            child: _buildCustomersList(customersState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/create'),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
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
                child: DropdownButtonFormField<CustomerType?>(
                  initialValue: state.selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<CustomerType?>(
                        value: null, child: Text('Todos')),
                    ...CustomerType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        )),
                  ],
                  onChanged: (value) {
                    ref.read(customersProvider.notifier).setType(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<CustomerStatus?>(
                  initialValue: state.selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<CustomerStatus?>(
                        value: null, child: Text('Todos')),
                    ...CustomerStatus.values.map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        )),
                  ],
                  onChanged: (value) {
                    ref.read(customersProvider.notifier).setStatus(value);
                  },
                ),
              ),
            ],
          ),
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
              onPressed: () =>
                  ref.read(customersProvider.notifier).loadCustomers(),
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
              state.searchQuery != null ||
                      state.selectedType != null ||
                      state.selectedStatus != null
                  ? 'No se encontraron clientes con los filtros aplicados'
                  : 'Agrega tu primer cliente',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            if (state.searchQuery != null ||
                state.selectedType != null ||
                state.selectedStatus != null) ...[
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypeColor(customer.type).shade100,
                    child: Icon(
                      _getTypeIcon(customer.type),
                      color: _getTypeColor(customer.type).shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        if (customer.identification != null)
                          Text(
                            'CC: ${customer.identification}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        Text(
                          customer.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(customer.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: _getTypeIcon(customer.type),
                      label: customer.type.label,
                      color: _getTypeColor(customer.type),
                    ),
                  ),
                  if (customer.type == CustomerType.credit &&
                      customer.currentBalance > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.account_balance_wallet,
                        label:
                            'Deuda: \$${customer.currentBalance.toStringAsFixed(0)}',
                        color: Colors.red,
                      ),
                    ),
                  ] else if (customer.creditLimit > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.credit_card,
                        label:
                            'Cupo: \$${customer.creditLimit.toStringAsFixed(0)}',
                        color: Colors.blue,
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

  Widget _buildStatusBadge(CustomerStatus status) {
    MaterialColor color;
    switch (status) {
      case CustomerStatus.active:
        color = Colors.green;
        break;
      case CustomerStatus.inactive:
        color = Colors.grey;
        break;
      case CustomerStatus.blocked:
        color = Colors.red;
        break;
    }

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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
}
