import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:applicoresestacion/data/providers/printer_provider.dart';
import 'package:applicoresestacion/domain/models/credit_account.dart';

class CreditCard extends ConsumerWidget {
  final CreditAccount credit;
  final VoidCallback onTap;

  const CreditCard({
    super.key,
    required this.credit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = credit.balance;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Factura #${credit.order.orderNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          credit.order.customerName ?? 'Sin cliente',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      credit.isPaid ? 'Pagado' : 'Pendiente',
                      style: TextStyle(
                        color: credit.isPaid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: (credit.isPaid
                            ? Colors.green
                            : Colors.red)
                        .withAlpha(30),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildAmountColumn(
                      label: 'Total',
                      value: '\$${credit.total.toStringAsFixed(0)}',
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: _buildAmountColumn(
                      label: 'Pagado',
                      value: '\$${credit.totalPaid.toStringAsFixed(0)}',
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Expanded(
                    child: _buildAmountColumn(
                      label: 'Saldo',
                      value: '\$${balance.toStringAsFixed(0)}',
                      color: balance <= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              if (credit.hasPendingDelivery) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.delivery_dining,
                      size: 18,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Entrega pendiente: ${credit.totalDelivered}/${credit.totalQuantity}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _printReceipt(context, ref),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Re-imprimir recibo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await ref.read(printOrderReceiptProvider)(
      credit.order,
      credit.items,
      payments: credit.payments,
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Recibo enviado a imprimir'
              : 'Error al imprimir: ${result.message}',
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
