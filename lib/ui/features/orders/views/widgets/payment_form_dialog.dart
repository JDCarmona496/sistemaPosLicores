import 'package:flutter/material.dart';

import '../../../../../domain/models/order.dart';
import '../../../../../domain/models/payment.dart';

class PaymentFormDialog extends StatefulWidget {
  final Order order;
  final String? receivedBy;

  const PaymentFormDialog({super.key, required this.order, this.receivedBy});

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total pedido: \$${widget.order.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Referencia (opcional)',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (amount <= 0) return;
            Navigator.pop(
              context,
              Payment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                orderId: widget.order.id,
                customerId: widget.order.customerId,
                paymentMethod: _method,
                amount: amount,
                reference: _referenceController.text.isEmpty
                    ? null
                    : _referenceController.text,
                receivedBy: widget.receivedBy ?? '',
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              ),
            );
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
