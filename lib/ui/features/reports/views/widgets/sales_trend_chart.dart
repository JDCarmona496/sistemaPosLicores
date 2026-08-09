import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/models/reports/report_models.dart';
import 'chart_styles.dart';

class SalesTrendChart extends StatelessWidget {
  final List<SalesTrendPoint> data;

  const SalesTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return _EmptyChart(message: 'No hay datos de ventas para el período');
    }

    final maxY = data
        .map((e) => e.totalSales)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final paddedMaxY = (maxY == 0 ? 10.0 : maxY * 1.15).toDouble();
    final horizontalInterval = (paddedMaxY / 4).ceilToDouble();
    final bottomInterval =
        (data.length > 6 ? ((data.length / 5).ceil()) : 1).toDouble();

    return AspectRatio(
      aspectRatio: 1.8,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: LineChart(
            LineChartData(
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
                    reservedSize: 28,
                    interval: bottomInterval,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('dd/MM').format(data[index].date.toLocal()),
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
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.totalSales);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  preventCurveOverShooting: true,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  barWidth: 3,
                  color: colorScheme.primary,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(180),
                    ],
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withAlpha(60),
                        colorScheme.primary.withAlpha(10),
                      ],
                    ),
                  ),
                  dotData: FlDotData(
                    show: data.length <= 14,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: colorScheme.surface,
                        strokeWidth: 2,
                        strokeColor: colorScheme.primary,
                      );
                    },
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => ChartStyles.surfaceColor(context),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final point = data[spot.x.toInt()];
                      return LineTooltipItem(
                        '\$${ChartStyles.formatMoney(point.totalSales)}\n'
                        '${DateFormat('dd MMM').format(point.date.toLocal())}',
                        ChartStyles.tooltipTextStyle(context),
                      );
                    }).toList();
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
