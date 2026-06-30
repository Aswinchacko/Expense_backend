import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';

class WaveTrendChart extends StatelessWidget {
  const WaveTrendChart({super.key, required this.points, this.height = 120});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height);
    }

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    final maxY = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final chartMax = (maxY > 0 ? maxY * 1.2 : 100).toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: chartMax,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: FolioColors.foreground,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: FolioColors.foreground.withValues(alpha: 0.04),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class MonthScrubber extends StatelessWidget {
  const MonthScrubber({
    super.key,
    required this.selected,
    required this.onSelected,
    this.year,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final int? year;

  static const _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  @override
  Widget build(BuildContext context) {
    final y = year ?? selected.year;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(12, (i) {
          final month = DateTime(y, i + 1);
          final isActive = selected.month == i + 1 && selected.year == y;
          return GestureDetector(
            onTap: () => onSelected(month),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                _months[i],
                style: FolioTheme.labelStyle(context, size: 13).copyWith(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                  decoration: isActive ? TextDecoration.underline : null,
                  decorationThickness: 2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.label,
    required this.amount,
    required this.percent,
    required this.icon,
    this.currency = '\$',
  });

  final String label;
  final double amount;
  final int percent;
  final String icon;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: FolioTheme.labelStyle(context))),
              Text('$currency${amount.toStringAsFixed(0)}', style: FolioTheme.labelStyle(context)),
              const SizedBox(width: 8),
              Text('$percent%', style: FolioTheme.metaStyle(context)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 4,
              backgroundColor: FolioColors.barTrack,
              color: FolioColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.name,
    required this.spent,
    required this.total,
    required this.percent,
  });

  final String name;
  final double spent;
  final double total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: FolioTheme.labelStyle(context)),
              Text(
                '\$${spent.toStringAsFixed(0)} / \$${total.toStringAsFixed(0)}',
                style: FolioTheme.metaStyle(context, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: FolioColors.barTrack,
              color: FolioColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
