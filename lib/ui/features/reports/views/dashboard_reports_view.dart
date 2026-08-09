import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/reports_providers.dart';
import 'widgets/chart_styles.dart';
import 'widgets/hourly_sales_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/payment_method_chart.dart';
import 'widgets/sales_by_seller_table.dart';
import 'widgets/sales_trend_chart.dart';
import 'widgets/section_header.dart';

class DashboardReportsView extends ConsumerWidget {
  const DashboardReportsView({super.key});

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
            title: 'Resumen del período',
            subtitle: 'Métricas clave de ventas y órdenes',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              KpiCard(
                title: 'Ventas totales',
                value: ChartStyles.formatMoney(state.salesSummary.totalSales),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              KpiCard(
                title: 'Órdenes',
                value: '${state.salesSummary.totalOrders}',
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
              KpiCard(
                title: 'Ticket promedio',
                value: ChartStyles.formatMoney(state.salesSummary.averageTicket),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              KpiCard(
                title: 'Pendientes',
                value:
                    '${state.pendingOrders.pendingCount} · ${ChartStyles.formatMoney(state.pendingOrders.pendingTotal)}',
                icon: Icons.pending_actions,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Tendencia de ventas',
            subtitle: 'Evolución diaria del total vendido',
          ),
          const SizedBox(height: 12),
          SalesTrendChart(data: state.salesTrend),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Ventas por método de pago',
            subtitle: 'Distribución de pagos recibidos',
          ),
          const SizedBox(height: 12),
          PaymentMethodChart(data: state.salesByPayment),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Ventas por hora',
            subtitle: 'Actividad de ventas del día seleccionado',
          ),
          const SizedBox(height: 12),
          HourlySalesChart(data: state.hourlySales),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Ventas por vendedor',
            subtitle: 'Desempeño del equipo en el período',
          ),
          const SizedBox(height: 12),
          SalesBySellerTable(data: state.salesBySeller),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
