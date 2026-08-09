import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/models/reports/report_models.dart';
import 'chart_styles.dart';

class PaymentMethodChart extends StatelessWidget {
  final List<SalesByPaymentMethod> data;

  const PaymentMethodChart({super.key, required this.data});

  static String _labelFor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'nequi':
        return 'Nequi';
      case 'daviplata':
        return 'Daviplata';
      case 'transfer':
        return 'Transferencia';
      case 'card':
        return 'Tarjeta';
      case 'credit':
        return 'Crédito';
      default:
        return method.isEmpty ? 'Otro' : method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = data.where((e) => e.amount > 0).toList();

    if (filtered.isEmpty) {
      return const AspectRatio(
        aspectRatio: 1.6,
        child: _EmptyChart(message: 'No hay pagos en el período'),
      );
    }

    final total = filtered.fold<double>(0, (a, b) => a + b.amount);

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 48,
                    borderData: FlBorderData(show: false),
                    sections: filtered.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final percentage = total == 0 ? 0 : item.amount / total;
                      final color = ChartStyles.palette[
                          index % ChartStyles.palette.length];
                      return PieChartSectionData(
                        color: color,
                        value: item.amount,
                        title: '${(percentage * 100).toStringAsFixed(0)}%',
                        radius: 36,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        titlePositionPercentageOffset: 0.55,
                      );
                    }).toList(),
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (event, response) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: filtered.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = ChartStyles.palette[
                      index % ChartStyles.palette.length];
                  return _LegendItem(
                    color: color,
                    label: _labelFor(item.paymentMethod),
                    amount: item.amount,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: ChartStyles.chartSubtitleStyle(context),
        ),
        const SizedBox(width: 4),
        Text(
          '\$${ChartStyles.formatMoney(amount)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(message, style: ChartStyles.chartSubtitleStyle(context)),
      ),
    );
  }
}
