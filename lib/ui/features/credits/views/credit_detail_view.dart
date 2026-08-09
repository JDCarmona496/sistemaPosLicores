import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:applicoresestacion/data/providers/credit_providers.dart';
import 'package:applicoresestacion/data/providers/user_providers.dart';
import 'package:applicoresestacion/domain/models/credit_account.dart';
import 'package:applicoresestacion/domain/models/order.dart';
import 'package:applicoresestacion/domain/models/payment.dart';
import 'package:applicoresestacion/domain/models/user.dart';
import 'package:applicoresestacion/ui/features/orders/views/widgets/payment_form_dialog.dart';

class CreditDetailView extends ConsumerWidget {
  final CreditAccount credit;

  const CreditDetailView({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = credit.balance;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoCard(context),
                      const SizedBox(height: 16),
                      _buildBalanceCard(context, balance),
                      const SizedBox(height: 16),
                      if (credit.hasPendingDelivery)
                        _buildPendingDeliveryCard(context),
                      if (credit.hasPendingDelivery)
                        const SizedBox(height: 16),
                      _buildPaymentsSection(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                if (balance > 0) _buildActionButtons(context, ref, balance),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final order = credit.order;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Factura #${order.orderNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(
                  label: Text(order.status.label),
                  backgroundColor: _statusColor(order.status).withAlpha(50),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${order.customerName ?? 'Sin cliente'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (order.customerPhone != null) ...[
              const SizedBox(height: 4),
              Text('Teléfono: ${order.customerPhone}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Fecha: ${order.createdAt?.toLocal().toString().substring(0, 16) ?? 'N/A'}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text('Tipo de entrega: ${order.deliveryType.label}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total factura:', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '\$${credit.total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total pagado:', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '\$${credit.totalPaid.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo pendiente:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '\$${balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: balance <= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingDeliveryCard(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delivery_dining, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text(
                  'Entrega pendiente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Entregados ${credit.totalDelivered} de ${credit.totalQuantity} productos',
            ),
            if (credit.pendingQuantity > 0)
              Text(
                'Faltan ${credit.pendingQuantity} unidades',
                style: TextStyle(color: Colors.orange.shade900),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abonos / Pagos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (credit.payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay abonos registrados'),
            ),
          )
        else
          ...credit.payments.map((payment) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text(
                    '${payment.paymentMethod.label} - \$${payment.amount.toStringAsFixed(0)}',
                  ),
                  subtitle: Text(
                    payment.createdAt?.toLocal().toString().substring(0, 16) ??
                        'N/A',
                  ),
                  trailing: payment.reference != null
                      ? Text(payment.reference!,
                          style: const TextStyle(fontSize: 12))
                      : null,
                ),
              )),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    double balance,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _recordPayment(context, ref, balance),
                icon: const Icon(Icons.add),
                label: const Text('Abonar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _recordPayment(context, ref, balance,
                    fullPayment: true),
                icon: const Icon(Icons.payment),
                label: const Text('Pagar total'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    double balance, {
    bool fullPayment = false,
  }) async {
    final User user;
    try {
      user = await ref.read(currentUserProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el usuario actual')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final payment = await showDialog<Payment>(
      context: context,
      builder: (context) => PaymentFormDialog(
        order: credit.order,
        receivedBy: user.id,
        initialAmount: fullPayment ? balance : null,
      ),
    );

    if (payment == null) return;
    if (!context.mounted) return;

    final amount = fullPayment ? balance : payment.amount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a cero')),
      );
      return;
    }

    try {
      final makePayment = ref.read(creditPaymentProvider);
      await makePayment(
        orderId: credit.order.id,
        customerId: credit.order.customerId,
        paymentMethod: payment.paymentMethod,
        amount: amount,
        reference: payment.reference,
        receivedBy: user.id,
        notes: payment.notes,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Abono de \$${amount.toStringAsFixed(0)} registrado correctamente'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar pago: $e')),
        );
      }
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.inTransit:
      case OrderStatus.ready:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
