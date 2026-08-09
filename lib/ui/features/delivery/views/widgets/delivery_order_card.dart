import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../data/providers/delivery_providers.dart';
import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/providers/user_providers.dart';
import '../../../../../domain/models/order.dart';
import '../../../../../domain/models/user.dart';
import '../../../../../domain/services/route_optimizer.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryOrderCard extends ConsumerWidget {
  final Order order;
  final Position? currentPosition;
  final VoidCallback? onComplete;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    this.currentPosition,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final distance = currentPosition != null
        ? RouteOptimizer.distanceToOrder(currentPosition!, order)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/delivery/order/${order.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colorScheme),
            _buildBody(context, colorScheme, distance),
            _buildActions(context, ref, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _getStatusColor(order.status).shade50,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getStatusColor(order.status),
            child: Text(
              '#${order.orderNumber}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName ?? 'Cliente',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (order.customerPhone != null)
                  Text(
                    order.customerPhone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          _buildStatusChip(order.status),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, ColorScheme colorScheme, double? distance) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.deliveryAddress != null)
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (distance != null && distance != double.infinity) ...[
                Icon(Icons.straighten, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  _formatDistance(distance),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Icon(Icons.payments_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '\$${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                Icon(Icons.note, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionChip(
            icon: Icons.phone,
            label: 'Llamar',
            color: Colors.green,
            onTap: order.customerPhone != null
                ? () => _callCustomer(order.customerPhone!)
                : null,
          ),
          _buildActionChip(
            icon: Icons.map,
            label: 'Navegar',
            color: Colors.blue,
            onTap: _openMap,
          ),
          if (_canDeliver)
            _buildActionChip(
              icon: Icons.check_circle,
              label: 'Entregar',
              color: colorScheme.primary,
              onTap: onComplete,
              filled: true,
            ),
          if (_canDeliver)
            _buildActionChip(
              icon: Icons.cancel,
              label: 'No entregó',
              color: Colors.red,
              onTap: () => _showDeliveryFailureDialog(context, ref),
              filled: true,
            ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool filled = false,
  }) {
    // Convertir Color a MaterialColor para acceder a shade
    final materialColor = color is MaterialColor ? color : Colors.grey;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 36,
          child: filled
              ? FilledButton.icon(
                  onPressed: onTap,
                  icon: Icon(icon, size: 16),
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: onTap,
                  icon: Icon(icon, size: 16, color: materialColor.shade700),
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: onTap != null ? materialColor.shade700 : Colors.grey,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: materialColor.shade700,
                    padding: EdgeInsets.zero,
                  ),
                ),
        ),
      ),
    );
  }

  bool get _canDeliver {
    return order.status == OrderStatus.inTransit ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.partiallyDelivered;
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap() async {
    final lat = order.deliveryLatitude;
    final lng = order.deliveryLongitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showDeliveryFailureDialog(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se pudo entregar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona el motivo:'),
            const SizedBox(height: 16),
            ...[
              'Cliente no responde',
              'Dirección errada',
              'Cliente no disponible',
              'Producto dañado/perdido',
              'Otro',
            ].map((r) => ListTile(
                  title: Text(r),
                  onTap: () => Navigator.pop(context, r),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    final User currentUser;
    try {
      currentUser = await ref.read(currentUserProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el usuario actual')),
        );
      }
      return;
    }

    try {
      await ref.read(ordersProvider.notifier).cancelOrder(
            id: order.id,
            reason: 'Domicilio no entregado: $reason',
            cancelledBy: currentUser.id,
          );
      ref.invalidate(deliveryOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega no completada registrada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusChip(OrderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
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

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  MaterialColor _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.inTransit:
        return Colors.indigo;
      case OrderStatus.partiallyDelivered:
        return Colors.teal;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
