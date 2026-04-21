import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/gameweek.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class SeasonTrendDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_GwDataPoint> dataPoints;
  final Color color;
  final IconData icon;
  final String Function(double) valueFormatter;

  const SeasonTrendDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dataPoints,
    required this.color,
    required this.icon,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppColors.secondary,
        ),
        body: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final values = dataPoints.map((d) => d.value).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final avgVal = values.reduce((a, b) => a + b) / values.length;

    final spots = dataPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), backgroundColor: AppColors.secondary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(maxVal, minVal, avgVal),
            const SizedBox(height: 16),
            _buildChart(context, spots, maxVal),
            const SizedBox(height: 16),
            _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double maxVal, double minVal, double avgVal) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            'Highest',
            valueFormatter(maxVal),
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _summaryTile('Average', valueFormatter(avgVal), color)),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryTile(
            'Lowest',
            valueFormatter(minVal),
            AppColors.textSecondary,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _summaryTile(String label, String value, Color tileColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: tileColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<FlSpot> spots, double maxVal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: color,
                            strokeWidth: 1.5,
                            strokeColor: AppColors.cardDark,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withAlpha(40),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        valueFormatter(v),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (dataPoints.length / 6).ceilToDouble().clamp(
                        1,
                        38,
                      ),
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= dataPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'GW${dataPoints[idx].gwId}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxVal * 1.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardDark,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        final gwId = idx < dataPoints.length
                            ? dataPoints[idx].gwId
                            : idx + 1;
                        return LineTooltipItem(
                          'GW$gwId\n${valueFormatter(s.y)}',
                          TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTable() {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 60,
                  child: Text(
                    'GW',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Value',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ...dataPoints.reversed.map(
            (dp) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'GW${dp.gwId}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      valueFormatter(dp.value),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _GwDataPoint {
  final int gwId;
  final double value;

  const _GwDataPoint(this.gwId, this.value);
}

/// Helper factory for season trend screens
class SeasonTrendScreenFactory {
  static SeasonTrendDetailScreen avgScore(List<Gameweek> finishedGws) {
    final points = finishedGws
        .where((gw) => gw.averageEntryScore != null)
        .map((gw) => _GwDataPoint(gw.id, gw.averageEntryScore!.toDouble()))
        .toList();
    return SeasonTrendDetailScreen(
      title: 'GW Avg Score',
      subtitle: 'Average manager score per gameweek',
      dataPoints: points,
      color: AppColors.primary,
      icon: Icons.show_chart_rounded,
      valueFormatter: (v) => '${v.toInt()} pts',
    );
  }

  static SeasonTrendDetailScreen highScore(List<Gameweek> finishedGws) {
    final points = finishedGws
        .where((gw) => gw.highestScore != null)
        .map((gw) => _GwDataPoint(gw.id, gw.highestScore!.toDouble()))
        .toList();
    return SeasonTrendDetailScreen(
      title: 'GW High Score',
      subtitle: 'Highest manager score per gameweek',
      dataPoints: points,
      color: AppColors.warning,
      icon: Icons.emoji_events_rounded,
      valueFormatter: (v) => '${v.toInt()} pts',
    );
  }

  static SeasonTrendDetailScreen transfers(List<Gameweek> finishedGws) {
    final points = finishedGws
        .map((gw) => _GwDataPoint(gw.id, gw.transfersMade.toDouble()))
        .toList();
    return SeasonTrendDetailScreen(
      title: 'Transfers / GW',
      subtitle: 'Total transfers made per gameweek',
      dataPoints: points,
      color: AppColors.accent,
      icon: Icons.swap_horiz_rounded,
      valueFormatter: (v) => v >= 1000
          ? '${(v / 1000).toStringAsFixed(0)}k'
          : v.toInt().toString(),
    );
  }
}
