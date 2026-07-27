import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/delivery_providers.dart';
import '../../../../domain/services/order_zone_grouper.dart';
import 'widgets/delivery_order_card.dart';
import 'widgets/delivery_zone_group_card.dart';

class DeliveryView extends ConsumerStatefulWidget {
  const DeliveryView({super.key});

  @override
  ConsumerState<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends ConsumerState<DeliveryView> {
  @override
  void initState() {
    super.initState();
    // Cargar domicilios solo si aún no hay datos (evita recargas duplicadas).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deliveryState = ref.read(deliveryOrdersProvider);
      if (deliveryState.orders.isEmpty && !deliveryState.isLoading) {
        ref.read(deliveryOrdersProvider.notifier).loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryOrdersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Domicilios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(deliveryOrdersProvider.notifier).refresh(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(deliveryState, colorScheme),
          _buildViewModeBar(deliveryState, colorScheme),
          Expanded(
            child: _buildContent(deliveryState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(DeliveryOrdersState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Por entregar',
            count: state.activeOrders.length,
            isSelected: state.filter == DeliveryFilter.active,
            color: Colors.indigo,
            onTap: () => ref
                .read(deliveryOrdersProvider.notifier)
                .setFilter(DeliveryFilter.active),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Entregados',
            count: state.deliveredOrders.length,
            isSelected: state.filter == DeliveryFilter.delivered,
            color: Colors.green,
            onTap: () => ref
                .read(deliveryOrdersProvider.notifier)
                .setFilter(DeliveryFilter.delivered),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Todos',
            count: state.orders.length,
            isSelected: state.filter == DeliveryFilter.all,
            color: Colors.blue,
            onTap: () => ref
                .read(deliveryOrdersProvider.notifier)
                .setFilter(DeliveryFilter.all),
          ),
          const Spacer(),
          Text(
            '${state.filteredOrders.length} pedidos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color.shade200 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeBar(DeliveryOrdersState state, ColorScheme colorScheme) {
    if (state.filter == DeliveryFilter.delivered) {
      // Para entregados solo lista
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<DeliveryViewMode>(
              segments: const [
                ButtonSegment(
                  value: DeliveryViewMode.list,
                  label: Text('Lista'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: DeliveryViewMode.zones,
                  label: Text('Por zona'),
                  icon: Icon(Icons.map),
                ),
              ],
              selected: {state.viewMode},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  ref
                      .read(deliveryOrdersProvider.notifier)
                      .setViewMode(selection.first);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            state.viewMode == DeliveryViewMode.zones
                ? 'Agrupado por cercanía'
                : 'Orden de llegada',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DeliveryOrdersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error al cargar domicilios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(deliveryOrdersProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = state.filteredOrders;

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.filter == DeliveryFilter.delivered
                    ? Icons.check_circle_outline
                    : Icons.delivery_dining,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                state.filter == DeliveryFilter.delivered
                    ? 'No hay entregas completadas'
                    : 'No tienes domicilios pendientes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.filter == DeliveryFilter.delivered
                    ? 'Las entregas completadas aparecerán aquí'
                    : 'Cuando te asignen un domicilio, aparecerá aquí',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              if (state.filter == DeliveryFilter.active)
                Text(
                  'Estados visibles: Listo, En camino, Entrega parcial',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(deliveryOrdersProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Entregados: siempre lista
    if (state.filter == DeliveryFilter.delivered) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(deliveryOrdersProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => DeliveryOrderCard(
            order: orders[index],
            currentPosition: null,
            onComplete: null,
          ),
        ),
      );
    }

    // Vista Lista
    if (state.viewMode == DeliveryViewMode.list) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(deliveryOrdersProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => DeliveryOrderCard(
            order: orders[index],
            currentPosition: null,
            onComplete: () =>
                ref.read(deliveryOrdersProvider.notifier).refresh(),
          ),
        ),
      );
    }

    // Vista Por zona
    final grouper = ref.read(orderZoneGrouperProvider);
    final zoneResult = grouper.group(orders);

    // Dentro de cada zona, mantener orden de llegada (FIFO).
    final sortedZones = zoneResult.zones.map((zone) {
      final sortedOrders = [...zone.orders]..sort((a, b) {
          final dateA = a.createdAt ?? DateTime.now();
          final dateB = b.createdAt ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
      return OrderZone(
        zoneNumber: zone.zoneNumber,
        orders: sortedOrders,
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(deliveryOrdersProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Resumen de ruta
          SliverToBoxAdapter(
            child: _buildRouteSummary(orders.length, state),
          ),
          // Zonas
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => DeliveryZoneGroupCard(
                  zone: sortedZones[index],
                  currentPosition: null,
                  onComplete: () =>
                      ref.read(deliveryOrdersProvider.notifier).refresh(),
                ),
                childCount: sortedZones.length,
              ),
            ),
          ),
          // Sin ubicación
          if (zoneResult.withoutLocation.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Sin ubicación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => DeliveryOrderCard(
                    order: zoneResult.withoutLocation[index],
                    currentPosition: null,
                    onComplete: () =>
                        ref.read(deliveryOrdersProvider.notifier).refresh(),
                  ),
                  childCount: zoneResult.withoutLocation.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummary(int totalOrders, DeliveryOrdersState state) {
    if (totalOrders == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.shopping_cart,
            value: '$totalOrders',
            label: 'Pedidos',
          ),
          _buildSummaryItem(
            icon: Icons.route,
            value: '${state.activeOrders.length}',
            label: 'Por entregar',
          ),
          _buildSummaryItem(
            icon: Icons.check_circle,
            value: '${state.deliveredOrders.length}',
            label: 'Entregados',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
