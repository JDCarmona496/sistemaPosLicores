import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/order_providers.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/services/order_zone_grouper.dart';
import 'widgets/order_card.dart';
import 'widgets/order_filter_bar.dart';
import 'widgets/order_zone_group_card.dart';

enum OrdersViewMode { list, zones }

class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  final _searchController = TextEditingController();
  OrdersViewMode _viewMode = OrdersViewMode.list;

  /// Colores de acento rotativos para distinguir zonas visualmente.
  static const _zoneAccents = <MaterialColor>[
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.purple,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: Column(
        children: [
          OrderFilterBar(searchController: _searchController),
          _buildViewModeSelector(),
          Expanded(
            child: _buildBody(ordersState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/create'),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nuevo Pedido'),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          SegmentedButton<OrdersViewMode>(
            segments: const [
              ButtonSegment(
                value: OrdersViewMode.list,
                icon: Icon(Icons.view_list, size: 18),
                label: Text('Lista'),
              ),
              ButtonSegment(
                value: OrdersViewMode.zones,
                icon: Icon(Icons.route, size: 18),
                label: Text('Por zona'),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selected) {
              setState(() => _viewMode = selected.first);
            },
          ),
          const Spacer(),
          if (_viewMode == OrdersViewMode.zones)
            Tooltip(
              message:
                  'Agrupa domicilios a menos de 500m para combinar viajes',
              child: Icon(Icons.info_outline,
                  size: 18, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(OrdersState state) {
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
              onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return _buildEmptyState(state);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
      child: _viewMode == OrdersViewMode.list
          ? _buildFlatList(state.orders)
          : _buildZoneList(state.orders),
    );
  }

  Widget _buildFlatList(List<Order> orders) {
    return ListView.builder(
      itemCount: orders.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => OrderCard(order: orders[index]),
    );
  }

  Widget _buildZoneList(List<Order> orders) {
    final result = const OrderZoneGrouper().group(orders);

    if (result.zones.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNoZonesNotice(result.withoutLocation.length),
          const SizedBox(height: 16),
          ...result.withoutLocation.map((order) => OrderCard(order: order)),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...result.zones.map((zone) => OrderZoneGroupCard(
              zone: zone,
              accentColor:
                  _zoneAccents[(zone.zoneNumber - 1) % _zoneAccents.length],
            )),
        if (result.withoutLocation.isNotEmpty) ...[
          _buildWithoutLocationHeader(result.withoutLocation.length),
          const SizedBox(height: 8),
          ...result.withoutLocation.map((order) => OrderCard(order: order)),
        ],
      ],
    );
  }

  Widget _buildNoZonesNotice(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blueGrey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ningún pedido tiene coordenadas de entrega registradas. '
              'Los pedidos con GPS se agruparán por zona automáticamente.',
              style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithoutLocationHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            'Sin ubicación ($count)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(OrdersState state) {
    final hasFilters = state.searchQuery != null ||
        state.selectedStatus != null ||
        state.selectedSaleType != null ||
        state.selectedDeliveryType != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'No se encontraron pedidos con los filtros aplicados'
                : 'Crea tu primer pedido',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(ordersProvider.notifier).clearFilters();
                _searchController.clear();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/orders/create'),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Crear primer pedido'),
            ),
          ],
        ],
      ),
    );
  }
}
