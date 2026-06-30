import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import 'category_icon.dart';

/// Cumulative balance sparkline — fills the month, handles negatives.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.points,
    this.height = 120,
    this.label,
    this.showZeroLine = true,
  });

  final List<TrendPoint> points;
  final double height;
  final String? label;
  final bool showZeroLine;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('No data yet', style: FolioText.meta12)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: FolioText.meta12),
          const SizedBox(height: 8),
        ],
        RepaintBoundary(
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(points: points, showZeroLine: showZeroLine),
            ),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.showZeroLine});

  final List<TrendPoint> points;
  final bool showZeroLine;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points.map((p) => p.amount).toList();
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final range = maxY - minY;

    double yFor(double v) => size.height - ((v - minY) / range) * size.height;

    if (showZeroLine && minY < 0 && maxY > 0) {
      final zeroY = yFor(0);
      canvas.drawLine(
        Offset(0, zeroY),
        Offset(size.width, zeroY),
        Paint()
          ..color = FolioColors.border
          ..strokeWidth = 1,
      );
    }

    if (points.length == 1) {
      final x = size.width / 2;
      final y = yFor(points.first.amount);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = FolioColors.foreground);
      return;
    }

    final dx = size.width / (points.length - 1);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = yFor(points[i].amount);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * dx;
        final prevY = yFor(points[i - 1].amount);
        final cx = (prevX + x) / 2;
        path.cubicTo(cx, prevY, cx, y, x, y);
      }
    }

    // Stroke only — filling to a zero baseline paints a huge grey slab when net is negative.
    canvas.drawPath(
      path,
      Paint()
        ..color = FolioColors.foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.showZeroLine != showZeroLine;
}

/// Daily spend bars for the month.
class DailySpendChart extends StatelessWidget {
  const DailySpendChart({
    super.key,
    required this.points,
    this.height = 120,
    this.clipToActiveDays = false,
  });

  final List<TrendPoint> points;
  final double height;
  final bool clipToActiveDays;

  @override
  Widget build(BuildContext context) {
    final active = clipToActiveDays
        ? points.where((p) => p.amount > 0).toList()
        : points;
    final data = active.isEmpty ? points : active;

    if (data.every((p) => p.amount == 0)) {
      return SizedBox(
        height: height,
        child: Center(child: Text('No spending this month', style: FolioText.meta12)),
      );
    }

    final maxY = data.fold<double>(0, (m, p) => math.max(m, p.amount));
    final chartMax = maxY > 0 ? maxY * 1.15 : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _DailyBarPainter(points: data, chartMax: chartMax),
        ),
      ),
    );
  }
}

class _DailyBarPainter extends CustomPainter {
  _DailyBarPainter({required this.points, required this.chartMax});

  final List<TrendPoint> points;
  final double chartMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final barW = size.width / points.length;
    final gap = math.min(barW * 0.4, 6.0);

    for (var i = 0; i < points.length; i++) {
      final amount = points[i].amount;
      if (amount <= 0) continue;
      final h = math.max((amount / chartMax) * size.height, 3.0);
      final x = i * barW + gap / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, math.max(barW - gap, 2), h),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = FolioColors.foreground.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_DailyBarPainter old) =>
      old.points != points || old.chartMax != chartMax;
}

/// Category split donut.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.categories,
    this.size = 160,
  });

  final List<CategoryBreakdown> categories;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(child: Text('No categories yet', style: FolioText.meta12)),
      );
    }

    final top = categories.take(5).toList();
    final otherTotal = categories.skip(5).fold<double>(0, (s, c) => s + c.total);
    final slices = [...top];
    if (otherTotal > 0) {
      slices.add(CategoryBreakdown(
        categoryId: 'other',
        name: 'Other',
        icon: 'ic:category',
        total: otherTotal,
        percent: 0,
      ));
    }

    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices});

  final List<CategoryBreakdown> slices;

  static const _alphas = [1.0, 0.75, 0.55, 0.4, 0.28, 0.18];

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, c) => s + c.total);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 22.0;
    var start = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].total / total) * 2 * math.pi;
      final alpha = _alphas[i.clamp(0, _alphas.length - 1)];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        Paint()
          ..color = FolioColors.foreground.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices;
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
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                _months[i],
                style: isActive ? FolioText.label13Bold : FolioText.label13,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: highlight ? FolioColors.foreground : FolioColors.surfaceMuted,
          borderRadius: BorderRadius.circular(FolioRadii.pill),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: FolioText.meta12.copyWith(
                color: highlight ? FolioColors.background.withValues(alpha: 0.7) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: FolioText.label15.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? FolioColors.background : FolioColors.foreground,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: FolioText.meta12.copyWith(
                  color: highlight ? FolioColors.background.withValues(alpha: 0.6) : null,
                ),
              ),
            ],
          ],
        ),
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
    this.currency = r'$',
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
              CategoryIcon(icon: icon, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: FolioText.label14)),
              Text('$currency${amount.toStringAsFixed(0)}', style: FolioText.label14),
              const SizedBox(width: 8),
              Text('$percent%', style: FolioText.meta12),
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
    this.currency = r'$',
  });

  final String name;
  final double spent;
  final double total;
  final int percent;
  final String currency;

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
              Text(name, style: FolioText.label14),
              Text(
                '$currency${spent.toStringAsFixed(0)} / $currency${total.toStringAsFixed(0)}',
                style: FolioText.meta12,
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
