import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/reports_providers.dart';
import 'widgets/chart_styles.dart';
import 'widgets/section_header.dart';
import 'widgets/top_products_table.dart';

class ProductsReportView extends ConsumerWidget {
  const ProductsReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Productos más vendidos',
            subtitle: 'Top de productos por cantidad vendida',
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricRow(
                    label: 'Productos en el ranking',
                    value: '${state.topProducts.length}',
                  ),
                  _MetricRow(
                    label: 'Unidades vendidas',
                    value: state.topProducts
                        .fold<int>(0, (a, b) => a + b.totalQuantity)
                        .toString(),
                  ),
                  _MetricRow(
                    label: 'Ingresos del top',
                    value: '\$${ChartStyles.formatMoney(state.topProducts.fold<double>(0, (a, b) => a + b.totalSales))}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TopProductsTable(data: state.topProducts),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: ChartStyles.mutedTextColor(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
