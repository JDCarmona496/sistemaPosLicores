import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:applicoresestacion/data/providers/credit_providers.dart';
import 'package:applicoresestacion/domain/models/credit_account.dart';
import 'credit_detail_view.dart';
import 'widgets/credit_card.dart';

class CreditsView extends ConsumerWidget {
  const CreditsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(creditsProvider.notifier).refresh(),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: creditsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (credits) {
          if (credits.isEmpty) {
            return const Center(
              child: Text('No hay facturas a crédito registradas'),
            );
          }

          final totalBalance = credits.fold<double>(
            0,
            (sum, c) => sum + c.balance,
          );

          return Column(
            children: [
              _buildSummaryHeader(context, credits, totalBalance),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: credits.length,
                  itemBuilder: (context, index) {
                    final credit = credits[index];
                    return CreditCard(
                      credit: credit,
                      onTap: () => _openDetail(context, credit),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    List<CreditAccount> credits,
    double totalBalance,
  ) {
    final pendingDeliveries = credits.where((c) => c.hasPendingDelivery).length;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de créditos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    label: 'Facturas',
                    value: credits.length.toString(),
                    icon: Icons.receipt,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    label: 'Saldo total',
                    value: '\$${totalBalance.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    valueColor: totalBalance > 0 ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    label: 'Pendientes',
                    value: pendingDeliveries.toString(),
                    icon: Icons.delivery_dining,
                    valueColor:
                        pendingDeliveries > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, CreditAccount credit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreditDetailView(credit: credit),
    );
  }
}
