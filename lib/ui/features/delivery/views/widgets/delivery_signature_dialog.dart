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
import 'signature_pad.dart';

/// Diálogo solo de firma para completar una entrega. Fuerza orientación
/// horizontal en móvil para que el campo de firma sea amplio.
class DeliverySignatureDialog extends ConsumerStatefulWidget {
  final Order order;
  final List<({String orderItemId, int quantityDelivered})> itemsToDeliver;

  const DeliverySignatureDialog({
    super.key,
    required this.order,
    required this.itemsToDeliver,
  });

  static Future<bool> show(
    BuildContext context, {
    required Order order,
    required List<({String orderItemId, int quantityDelivered})> itemsToDeliver,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          useSafeArea: true,
          builder: (context) => DeliverySignatureDialog(
            order: order,
            itemsToDeliver: itemsToDeliver,
          ),
        ) ??
        false;
  }

  @override
  ConsumerState<DeliverySignatureDialog> createState() =>
      _DeliverySignatureDialogState();
}

class _DeliverySignatureDialogState
    extends ConsumerState<DeliverySignatureDialog> {
  final _signatureKey = GlobalKey<SignaturePadState>();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      title: const Text('Firma del cliente'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.75,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SignaturePad(key: _signatureKey),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ],
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
            items: widget.itemsToDeliver,
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
