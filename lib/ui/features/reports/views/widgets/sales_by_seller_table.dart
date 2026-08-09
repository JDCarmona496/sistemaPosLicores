import 'package:flutter/material.dart';

import '../../../../../domain/models/reports/report_models.dart';
import 'chart_styles.dart';

class SalesBySellerTable extends StatelessWidget {
  final List<SalesBySeller> data;

  const SalesBySellerTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'No hay vendedores con ventas en el período',
              style: ChartStyles.chartSubtitleStyle(context),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 32,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHighest.withAlpha(128),
            ),
            columns: const [
              DataColumn(label: Text('Vendedor')),
              DataColumn(label: Text('Órdenes'), numeric: true),
              DataColumn(label: Text('Ventas'), numeric: true),
            ],
            rows: data.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item.sellerName)),
                  DataCell(Text('${item.orderCount}')),
                  DataCell(
                    Text(
                      '\$${ChartStyles.formatMoney(item.totalSales)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
