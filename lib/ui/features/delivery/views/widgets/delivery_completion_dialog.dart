import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../data/providers/delivery_providers.dart';
import '../../../../../data/providers/order_providers.dart';
import '../../../../../data/services/delivery_evidence_service.dart';
import '../../../../../domain/models/order.dart';
import '../../../../../domain/models/order_item.dart';
import 'signature_pad.dart';

/// Diálogo completo de entrega de un pedido: selecciona ítems, firma y foto.
class DeliveryCompletionDialog extends ConsumerStatefulWidget {
  final Order order;
  final List<OrderItem> items;

  const DeliveryCompletionDialog({
    super.key,
    required this.order,
    required this.items,
  });

  static Future<bool> show(
    BuildContext context, {
    required Order order,
    required List<OrderItem> items,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => DeliveryCompletionDialog(
            order: order,
            items: items,
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
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, int> _totalDelivered = {};
  XFile? _photoFile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _totalDelivered[item.id] = item.quantityDelivered;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Completar entrega'),
      content: SizedBox(
        width: double.maxFinite,
        height: 520,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSectionTitle('Ítems entregados'),
                    ...widget.items.map(_buildItemField),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Firma del cliente'),
                    SignaturePad(key: _signatureKey),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Foto de entrega (opcional)'),
                    _buildPhotoPicker(),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

  Widget _buildPhotoPicker() {
    return InkWell(
      onTap: _isLoading ? null : _pickPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _photoFile == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 32),
                    SizedBox(height: 8),
                    Text('Toca para adjuntar foto'),
                  ],
                ),
              )
            : FutureBuilder<Uint8List?>(
                future: _photoFile!.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _photoFile = file);
      }
    } catch (e) {
      setState(() => _error = 'No se pudo seleccionar la foto: $e');
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

      // 3. Subir foto si existe.
      String? photoUrl;
      if (_photoFile != null) {
        final photoBytes = await _photoFile!.readAsBytes();
        final ext = _photoFile!.name.split('.').lastOrNull;
        photoUrl = await evidenceService.uploadPhoto(
          orderId: widget.order.id,
          bytes: photoBytes,
          fileExtension: ext,
        );
      }

      // 4. Registrar evidencia en el pedido.
      final repository = ref.read(orderRepositoryProvider);
      await repository.recordDeliveryEvidence(
        orderId: widget.order.id,
        photoUrl: photoUrl,
        signatureBase64: signatureUrl,
        deliveredAt: DateTime.now(),
      );

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
