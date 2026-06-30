import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import 'category_icon.dart';

/// Lightweight sparkline — no fl_chart, repaints in one pass.
class SparklineChart extends StatelessWidget {
  const SparklineChart({super.key, required this.points, this.height = 120});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return SizedBox(height: height);
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(points: points),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points});

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final maxY = points.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    final chartMax = maxY > 0 ? maxY * 1.15 : 1.0;
    final dx = size.width / (points.length - 1);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = size.height - (points[i].amount / chartMax) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * dx;
        final prevY = size.height - (points[i - 1].amount / chartMax) * size.height;
        final cx = (prevX + x) / 2;
        path.cubicTo(cx, prevY, cx, y, x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = FolioColors.foreground.withValues(alpha: 0.06));
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
  bool shouldRepaint(_SparklinePainter old) => old.points != points;
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
