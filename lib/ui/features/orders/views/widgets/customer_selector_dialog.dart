import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/customer_providers.dart';
import '../../../../../domain/models/customer.dart';

/// Resultado de la selección en [CustomerSelectorDialog].
/// Distingue entre "Cancelar", "Cliente ocasional" y un cliente específico.
class CustomerSelectionResult {
  final bool cancelled;
  final bool isOccasional;
  final Customer? customer;

  const CustomerSelectionResult._({
    this.cancelled = false,
    this.isOccasional = false,
    this.customer,
  });

  factory CustomerSelectionResult.cancelled() =>
      const CustomerSelectionResult._(cancelled: true);

  factory CustomerSelectionResult.occasional() =>
      const CustomerSelectionResult._(isOccasional: true);

  factory CustomerSelectionResult.customer(Customer customer) =>
      CustomerSelectionResult._(customer: customer);
}

/// Diálogo modal para seleccionar un cliente registrado o "Cliente ocasional".
class CustomerSelectorDialog extends ConsumerStatefulWidget {
  const CustomerSelectorDialog({super.key});

  @override
  ConsumerState<CustomerSelectorDialog> createState() =>
      _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState
    extends ConsumerState<CustomerSelectorDialog> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      ref.read(customersProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Seleccionar Cliente'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(customersProvider.notifier).setSearch(null);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(customersProvider.notifier)
                    .setSearch(value.isEmpty ? null : value);
              },
            ),
            const SizedBox(height: 8),
            if (customersState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customersState.error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          ref.read(customersProvider.notifier).loadCustomers(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: customersState.isLoading && customersState.customers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : customersState.customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey.shade700),
                              const SizedBox(height: 8),
                              Text(
                                customersState.error != null
                                    ? 'No se pudieron cargar los clientes'
                                    : 'No hay clientes registrados',
                                style: TextStyle(
                                    color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: customersState.customers.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(Icons.person_outline,
                                      color: Colors.grey.shade700),
                                ),
                                title: const Text('Cliente ocasional'),
                                subtitle: const Text(
                                    'Venta sin cliente registrado'),
                                onTap: () => Navigator.pop(
                                  context,
                                  CustomerSelectionResult.occasional(),
                                ),
                              );
                            }
                            final customer =
                                customersState.customers[index - 1];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                    customer.fullName[0].toUpperCase()),
                              ),
                              title: Text(customer.fullName),
                              subtitle: Text(customer.phone),
                              onTap: () => Navigator.pop(
                                context,
                                CustomerSelectionResult.customer(customer),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            CustomerSelectionResult.cancelled(),
          ),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
