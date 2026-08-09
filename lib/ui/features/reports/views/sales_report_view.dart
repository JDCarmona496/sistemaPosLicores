import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/reports_providers.dart';
import 'widgets/chart_styles.dart';
import 'widgets/payment_method_chart.dart';
import 'widgets/sales_by_seller_table.dart';
import 'widgets/sales_trend_chart.dart';
import 'widgets/section_header.dart';

class SalesReportView extends ConsumerWidget {
  const SalesReportView({super.key});

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
            title: 'Resumen financiero',
            subtitle: 'Ingresos, descuentos y domicilios del período',
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
                    label: 'Ventas totales',
                    value: ChartStyles.formatMoney(state.salesSummary.totalSales),
                  ),
                  _MetricRow(
                    label: 'Descuentos',
                    value: ChartStyles.formatMoney(state.salesSummary.totalDiscounts),
                    valueColor: Colors.red,
                  ),
                  _MetricRow(
                    label: 'Domicilios',
                    value: ChartStyles.formatMoney(state.salesSummary.totalDeliveryFees),
                  ),
                  const Divider(height: 24),
                  _MetricRow(
                    label: 'Total neto',
                    value: ChartStyles.formatMoney(
                      state.salesSummary.totalSales -
                          state.salesSummary.totalDiscounts +
                          state.salesSummary.totalDeliveryFees,
                    ),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Tendencia de ventas',
            subtitle: 'Comportamiento diario de ventas',
          ),
          const SizedBox(height: 12),
          SalesTrendChart(data: state.salesTrend),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Ventas por método de pago',
            subtitle: 'Desglose de pagos por canal',
          ),
          const SizedBox(height: 12),
          PaymentMethodChart(data: state.salesByPayment),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Ventas por vendedor',
            subtitle: 'Ranking por monto vendido',
          ),
          const SizedBox(height: 12),
          SalesBySellerTable(data: state.salesBySeller),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

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
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
