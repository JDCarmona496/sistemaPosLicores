import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/models/reports/report_models.dart';
import 'chart_styles.dart';

class HourlySalesChart extends StatelessWidget {
  final List<HourlySales> data;

  const HourlySalesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return const _EmptyChart(
        message: 'No hay ventas por hora para la fecha seleccionada',
      );
    }

    final maxY = data
        .map((e) => e.totalSales)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final paddedMaxY = (maxY == 0 ? 10.0 : maxY * 1.15).toDouble();
    final horizontalInterval = (paddedMaxY / 4).ceilToDouble();

    return AspectRatio(
      aspectRatio: 1.8,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: paddedMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: horizontalInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: ChartStyles.dividerColor(context),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: horizontalInterval,
                    getTitlesWidget: (value, _) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '\$${ChartStyles.compactMoney(value)}',
                          style: ChartStyles.axisTextStyle(context),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox();
                      }
                      final hour = data[index].hour;
                      // Mostrar cada 3 horas para no saturar.
                      if (hour % 3 != 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: ChartStyles.axisTextStyle(context),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.totalSales,
                      width: 10,
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colorScheme.primary.withAlpha(150),
                          colorScheme.primary,
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => ChartStyles.surfaceColor(context),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final hour = data[group.x.toInt()].hour;
                    return BarTooltipItem(
                      '${hour.toString().padLeft(2, '0')}:00\n'
                      '\$${ChartStyles.formatMoney(rod.toY)}',
                      ChartStyles.tooltipTextStyle(context),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Text(
            message,
            style: ChartStyles.chartSubtitleStyle(context),
          ),
        ),
      ),
    );
  }
}
