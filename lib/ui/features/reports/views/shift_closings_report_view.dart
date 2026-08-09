import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/providers/shift_closing_report_providers.dart';
import '../../../../domain/models/reports/shift_closing_report.dart';

class ShiftClosingsReportView extends ConsumerStatefulWidget {
  const ShiftClosingsReportView({super.key});

  @override
  ConsumerState<ShiftClosingsReportView> createState() =>
      _ShiftClosingsReportViewState();
}

class _ShiftClosingsReportViewState
    extends ConsumerState<ShiftClosingsReportView> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  }

  Color _differenceColor(double difference) {
    if (difference > 0) return Colors.green;
    if (difference < 0) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftClosingReportsProvider(_selectedDate));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Día: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => ref
                    .read(shiftClosingReportsProvider(_selectedDate).notifier)
                    .load(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Recargar',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            Expanded(
              child: Center(
                child: Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )
          else if (state.reports.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No hay cierres de caja para este día.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.reports.length,
                itemBuilder: (context, index) {
                  final report = state.reports[index];
                  return _ShiftClosingCard(
                    report: report,
                    formatMoney: _formatMoney,
                    formatDateTime: _formatDateTime,
                    differenceColor: _differenceColor,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ShiftClosingCard extends StatelessWidget {
  final ShiftClosingReport report;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDateTime;
  final Color Function(double) differenceColor;

  const _ShiftClosingCard({
    required this.report,
    required this.formatMoney,
    required this.formatDateTime,
    required this.differenceColor,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = differenceColor(report.difference);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('${report.cashRegisterName} - ${report.openedByName}'),
        subtitle: Text(
          'Cerrado: ${formatDateTime(report.closedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _InfoRow(label: 'Apertura', value: formatMoney(report.openingAmount)),
          _InfoRow(
            label: 'Conteo físico',
            value: formatMoney(report.closingAmount),
          ),
          _InfoRow(
            label: 'Efectivo neto (conteo - base)',
            value: formatMoney(report.netCashTotal),
            valueStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          _InfoRow(
            label: 'Ventas en efectivo esperadas',
            value: formatMoney(report.expectedCashSales),
          ),
          _InfoRow(
            label: 'Diferencia',
            value: formatMoney(report.difference),
            valueStyle: TextStyle(
              color: diffColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          _InfoRow(
            label: 'Total pagos recibidos',
            value: formatMoney(report.paymentsTotal),
          ),
          if (report.salesByUser.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pagos por usuario:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            ...report.salesByUser.map(
              (user) => _InfoRow(
                label: user.userName,
                value: formatMoney(user.totalPayments),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
