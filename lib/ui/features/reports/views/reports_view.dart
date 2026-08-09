import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/reports_providers.dart';
import 'dashboard_reports_view.dart';
import 'products_report_view.dart';
import 'sales_report_view.dart';
import 'shift_closings_report_view.dart';
import 'widgets/date_range_filter.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _applyRange() async {
    if (_dateFrom.isAfter(_dateTo)) return;
    await ref.read(reportsProvider.notifier).setDateRange(_dateFrom, _dateTo);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);

    // Sync local dates with provider dates when they change externally.
    _dateFrom = state.dateFrom;
    _dateTo = state.dateTo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.trending_up), text: 'Ventas'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Productos'),
            Tab(icon: Icon(Icons.point_of_sale), text: 'Cierres'),
          ],
        ),
      ),
      body: Column(
        children: [
          DateRangeFilter(
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            onDateFromChanged: (value) {
              setState(() => _dateFrom = value);
            },
            onDateToChanged: (value) {
              setState(() => _dateTo = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: state.isLoading
                  ? const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ElevatedButton.icon(
                      onPressed: _applyRange,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Aplicar rango'),
                    ),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MaterialBanner(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                content: Text(
                  state.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                leading: Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                actions: [
                  TextButton(
                    onPressed: () => ref
                        .read(reportsProvider.notifier)
                        .load(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                DashboardReportsView(),
                SalesReportView(),
                ProductsReportView(),
                ShiftClosingsReportView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
