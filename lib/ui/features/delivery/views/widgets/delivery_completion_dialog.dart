import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/customer_providers.dart';
import '../../../../../data/providers/delivery_providers.dart';
import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/services/delivery_evidence_service.dart';
import '../../../../../domain/models/order.dart';
import '../../../../../domain/models/order_item.dart';
import 'signature_pad.dart';

/// Diálogo de entrega: ítems + firma. Fuerza orientación horizontal en móvil.
class DeliveryCompletionDialog extends ConsumerStatefulWidget {
  final Order order;
  final List<OrderItem> items;
  final bool deliverAll;

  const DeliveryCompletionDialog({
    super.key,
    required this.order,
    required this.items,
    this.deliverAll = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required Order order,
    required List<OrderItem> items,
    bool deliverAll = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          useSafeArea: true,
          builder: (context) => DeliveryCompletionDialog(
            order: order,
            items: items,
            deliverAll: deliverAll,
          ),
        ) ??
        false;
  }

  @override
  ConsumerState<DeliveryCompletionDialog> createState() =>
      _DeliveryCompletionDialogState();
}

class _DeliveryCompletionDialogState
    extends ConsumerState<DeliveryCompletionDialog> {
  final _signatureKey = GlobalKey<SignaturePadState>();
  final Map<String, int> _totalDelivered = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _totalDelivered[item.id] = widget.deliverAll
          ? item.quantity
          : item.quantityDelivered;
    }
    _forceLandscapeIfMobile();
  }

  @override
  void dispose() {
    _restorePortraitIfMobile();
    super.dispose();
  }

  Future<void> _forceLandscapeIfMobile() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _restorePortraitIfMobile() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(8),
      title: Row(
        children: [
          const Expanded(child: Text('Completar entrega')),
          if (!_isAllDelivered())
            TextButton.icon(
              onPressed: _isLoading ? null : _deliverAll,
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('Entregar todo'),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.75,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 500;
                  return isWide
                      ? _buildHorizontalLayout()
                      : _buildVerticalLayout();
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _confirm,
          icon: const Icon(Icons.check),
          label: const Text('Confirmar entrega'),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemsSection(),
        const SizedBox(height: 16),
        _buildSectionTitle('Firma del cliente'),
        Expanded(child: SignaturePad(key: _signatureKey)),
        if (_error != null) _buildError(),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemsSection(),
                if (_error != null) _buildError(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Firma del cliente'),
              Expanded(
                child: SignaturePad(key: _signatureKey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionTitle('Ítems entregados'),
        ...widget.items.map(_buildItemField),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildItemField(OrderItem item) {
    final pending = item.quantity - item.quantityDelivered;
    final controller = TextEditingController(
      text: '${_totalDelivered[item.id] ?? 0}',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                Text(
                  'Pedido: ${item.quantity} · Pendiente: $pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) {
                _totalDelivered[item.id] = int.tryParse(value) ?? 0;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red.shade700),
      ),
    );
  }

  bool _isAllDelivered() {
    return widget.items.every((item) {
      final total = _totalDelivered[item.id] ?? 0;
      return total >= item.quantity;
    });
  }

  void _deliverAll() {
    setState(() {
      for (final item in widget.items) {
        _totalDelivered[item.id] = item.quantity;
      }
    });
  }

  Future<void> _updateCustomerCoordinates() async {
    final customerId = widget.order.customerId;
    if (customerId == null) return;

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.captureCurrentPosition();
      await ref.read(customersProvider.notifier).updateCoordinates(
            customerId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } catch (_) {
      // Silencioso: la entrega no debe fallar si no se puede capturar GPS.
    }
  }

  Future<void> _confirm() async {
    setState(() => _error = null);

    final itemsToDeliver = <({String orderItemId, int quantityDelivered})>[];
    for (final item in widget.items) {
      final total = _totalDelivered[item.id] ?? 0;
      if (total < item.quantityDelivered) {
        setState(() => _error =
            'No puedes reducir la cantidad entregada de ${item.productName ?? 'un producto'}. Verifica los datos.');
        return;
      }
      if (total > item.quantity) {
        setState(() => _error =
            'La cantidad entregada no puede superar la pedida en ${item.productName ?? 'un producto'}.');
        return;
      }
      if (total > item.quantityDelivered) {
        itemsToDeliver.add((
          orderItemId: item.id,
          quantityDelivered: total,
        ));
      }
    }

    if (itemsToDeliver.isEmpty) {
      setState(() => _error = 'Marca al menos un ítem como entregado.');
      return;
    }

    final signatureBytes = await _signatureKey.currentState?.exportPng();
    if (signatureBytes == null || signatureBytes.isEmpty) {
      setState(() => _error = 'Se requiere la firma del cliente.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Registrar ítems entregados.
      await ref.read(ordersProvider.notifier).markItemsDelivered(
            orderId: widget.order.id,
            items: itemsToDeliver,
          );

      // 2. Subir firma.
      final evidenceService = DeliveryEvidenceService();
      final signatureUrl = await evidenceService.uploadSignature(
        orderId: widget.order.id,
        bytes: signatureBytes,
      );

      // 3. Registrar evidencia en el pedido.
      final repository = ref.read(orderRepositoryProvider);
      await repository.recordDeliveryEvidence(
        orderId: widget.order.id,
        signatureBase64: signatureUrl,
        deliveredAt: DateTime.now(),
      );

      // 4. Capturar coordenada actual del domiciliario y actualizar cliente.
      await _updateCustomerCoordinates();

      // 5. Refrescar listado de domicilios.
      ref.invalidate(deliveryOrdersProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al registrar entrega: $e';
        });
      }
    }
  }
}
