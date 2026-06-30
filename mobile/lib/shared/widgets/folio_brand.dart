import 'package:flutter/material.dart';

import '../../core/theme/folio_theme.dart';

class FolioMonogram extends StatelessWidget {
  const FolioMonogram({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MonogramPainter(),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FolioColors.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    canvas.drawCircle(center, radius, paint);

    final diag = Paint()
      ..color = FolioColors.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.4),
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.4),
      diag,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FolioWordmark extends StatelessWidget {
  const FolioWordmark({super.key, this.showTagline = true});

  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'folio',
          style: FolioTheme.amountStyle(context, size: 40),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'your minimal expense tracker',
            style: FolioTheme.metaStyle(context, size: 13),
          ),
        ],
      ],
    );
  }
}
