import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive.dart';
import '../../../../../data/providers/order_providers.dart';
import '../../../../../domain/models/order.dart';

/// Barra de filtros siempre visible del modulo de pedidos.
/// En desktop muestra todo en una fila; en movil apila la busqueda
/// sobre los selectores.
class OrderFilterBar extends ConsumerWidget {
  final TextEditingController searchController;

  const OrderFilterBar({super.key, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    final hasActiveFilters = state.selectedStatus != null ||
        state.selectedSaleType != null ||
        state.selectedDeliveryType != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          if (context.isMobileOrTablet) ...[
            _buildSearch(context, ref),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatusDropdown(ref, state)),
                const SizedBox(width: 8),
                Expanded(child: _buildSaleTypeDropdown(ref, state)),
                const SizedBox(width: 8),
                Expanded(child: _buildDeliveryTypeDropdown(ref, state)),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: _buildSearch(context, ref)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildStatusDropdown(ref, state)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildSaleTypeDropdown(ref, state)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildDeliveryTypeDropdown(ref, state)),
              ],
            ),
          if (hasActiveFilters)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(ordersProvider.notifier).clearFilters();
                  searchController.clear();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, WidgetRef ref) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por número, cliente o teléfono...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  ref.read(ordersProvider.notifier).setSearch(null);
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      keyboardType: TextInputType.text,
      onChanged: (value) {
        ref.read(ordersProvider.notifier).setSearch(value.isEmpty ? null : value);
      },
    );
  }

  Widget _buildStatusDropdown(WidgetRef ref, OrdersState state) {
    return _FilterDropdown<OrderStatus?>(
      value: state.selectedStatus,
      label: 'Estado',
      icon: Icons.flag_outlined,
      highlighted: state.selectedStatus != null,
      items: [
        const DropdownMenuItem<OrderStatus?>(
            value: null, child: Text('Todos')),
        ...OrderStatus.values.map((status) => DropdownMenuItem(
              value: status,
              child: Text(status.label),
            )),
      ],
      onChanged: (value) => ref.read(ordersProvider.notifier).setStatus(value),
    );
  }

  Widget _buildSaleTypeDropdown(WidgetRef ref, OrdersState state) {
    return _FilterDropdown<SaleType?>(
      value: state.selectedSaleType,
      label: 'Venta',
      icon: Icons.payments_outlined,
      highlighted: state.selectedSaleType != null,
      items: [
        const DropdownMenuItem<SaleType?>(value: null, child: Text('Todas')),
        ...SaleType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type.label),
            )),
      ],
      onChanged: (value) => ref.read(ordersProvider.notifier).setSaleType(value),
    );
  }

  Widget _buildDeliveryTypeDropdown(WidgetRef ref, OrdersState state) {
    return _FilterDropdown<DeliveryType?>(
      value: state.selectedDeliveryType,
      label: 'Entrega',
      icon: Icons.local_shipping_outlined,
      highlighted: state.selectedDeliveryType != null,
      items: [
        const DropdownMenuItem<DeliveryType?>(
            value: null, child: Text('Todas')),
        ...DeliveryType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type.label),
            )),
      ],
      onChanged: (value) =>
          ref.read(ordersProvider.notifier).setDeliveryType(value),
    );
  }
}

/// Dropdown compacto de filtro: se resalta con el color primario
/// cuando tiene un valor activo.
class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData icon;
  final bool highlighted;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.highlighted,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        filled: highlighted,
        fillColor: highlighted
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : null,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
