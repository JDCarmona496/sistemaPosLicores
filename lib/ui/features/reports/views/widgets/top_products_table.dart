import 'package:flutter/material.dart';

import '../../../../../domain/models/reports/report_models.dart';
import 'chart_styles.dart';

class TopProductsTable extends StatelessWidget {
  final List<TopProductReport> data;

  const TopProductsTable({super.key, required this.data});

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
              'No hay productos vendidos en el período',
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
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Producto')),
              DataColumn(label: Text('Cantidad'), numeric: true),
              DataColumn(label: Text('Ventas'), numeric: true),
            ],
            rows: data.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(item.productName)),
                  DataCell(Text('${item.totalQuantity}')),
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
