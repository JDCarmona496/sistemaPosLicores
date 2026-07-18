import 'package:flutter/material.dart';

import '../../../../../domain/models/order_item.dart';

class DeliveryItemsDialog extends StatefulWidget {
  final List<OrderItem> items;

  const DeliveryItemsDialog({super.key, required this.items});

  @override
  State<DeliveryItemsDialog> createState() => _DeliveryItemsDialogState();
}

class _DeliveryItemsDialogState extends State<DeliveryItemsDialog> {
  late final Map<String, int> _deliveredQuantities;

  @override
  void initState() {
    super.initState();
    _deliveredQuantities = {
      for (final item in widget.items)
        item.id: item.quantityDelivered,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar entrega'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final pending = item.quantity - item.quantityDelivered;
            return ListTile(
              title: Text(item.productName ?? 'Producto'),
              subtitle: Text('Pendiente: $pending'),
              trailing: SizedBox(
                width: 80,
                child: TextField(
                  controller: TextEditingController(
                    text: '${_deliveredQuantities[item.id]}',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    _deliveredQuantities[item.id] =
                        int.tryParse(value) ?? 0;
                  },
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final result = <({String orderItemId, int quantityDelivered})>[];
            for (final item in widget.items) {
              if (item.pendingQuantity > 0) {
                result.add((
                  orderItemId: item.id,
                  quantityDelivered: item.quantity,
                ));
              }
            }
            Navigator.pop(context, result);
          },
          child: const Text('Entregar todo'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = <({String orderItemId, int quantityDelivered})>[];
            for (final item in widget.items) {
              final delivered = _deliveredQuantities[item.id] ?? 0;
              if (delivered > item.quantityDelivered) {
                result.add((
                  orderItemId: item.id,
                  quantityDelivered: delivered,
                ));
              }
            }
            Navigator.pop(context, result);
          },
          child: const Text('Guardar parcial'),
        ),
      ],
    );
  }
}
