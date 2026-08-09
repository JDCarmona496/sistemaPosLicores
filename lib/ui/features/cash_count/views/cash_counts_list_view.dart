import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/cash_count_providers.dart';
import '../../../../data/providers/printer_provider.dart';
import '../../../../domain/models/cash_count.dart';

class CashCountsListView extends ConsumerWidget {
  const CashCountsListView({super.key});

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _reprint(BuildContext context, WidgetRef ref, CashCount count) async {
    final result = await ref.read(printCashCountReceiptProvider)(count);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Recibo reimpreso'
              : 'Error al reimprimir: ${result.message}',
        ),
        backgroundColor: result.success ? null : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(currentShiftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de conteos'),
      ),
      body: shiftState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shiftState.error != null
              ? Center(child: Text('Error al cargar turno: ${shiftState.error}'))
              : shiftState.shift == null
                  ? const Center(
                      child: Text('No hay un turno abierto.'),
                    )
                  : _buildList(context, ref, shiftState.shift!.id),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, String shiftId) {
    final state = ref.watch(cashCountHistoryProvider(shiftId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(cashCountHistoryProvider(shiftId).notifier).load(),
                icon: const Icon(Icons.refresh),
                label: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.counts.isEmpty) {
      return const Center(
        child: Text('No hay conteos guardados en este turno.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(cashCountHistoryProvider(shiftId).notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.counts.length,
        itemBuilder: (context, index) {
          final count = state.counts[index];
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
                        _formatDate(count.createdAt),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print),
                        tooltip: 'Reimprimir',
                        onPressed: () => _reprint(context, ref, count),
                      ),
                    ],
                  ),
                  if (count.responsibleName?.isNotEmpty == true)
                    Text(
                      'Responsable: ${count.responsibleName}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Billetes: \$${_formatMoney(count.totalBills)}'),
                      Text('Monedas: \$${_formatMoney(count.totalCoins)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TOTAL: \$${_formatMoney(count.total)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (count.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notas: ${count.notes}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
