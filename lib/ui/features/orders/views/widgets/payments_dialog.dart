import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/providers/payment_providers.dart';
import '../../../../../domain/models/payment.dart';

class PaymentsDialog extends ConsumerWidget {
  final String orderId;

  const PaymentsDialog({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByOrderProvider(orderId));

    return AlertDialog(
      title: const Text('Pagos / Abonos'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const Center(child: Text('No hay pagos registrados'));
            }
            return ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text('${payment.paymentMethod.label} - \$${payment.amount.toStringAsFixed(0)}'),
                  subtitle: Text(payment.createdAt != null
                      ? payment.createdAt!.toLocal().toString().substring(0, 16)
                      : ''),
                  trailing: payment.reference != null
                      ? Text(payment.reference!, style: const TextStyle(fontSize: 12))
                      : null,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
