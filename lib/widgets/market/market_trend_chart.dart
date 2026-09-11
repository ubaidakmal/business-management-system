import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/market_data.dart';

class MarketTrendChart extends StatelessWidget {
  const MarketTrendChart({super.key, required this.points});

  final List<MarketHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Refresh a few times to see history.',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _MarketTrendPainter(points: points),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MarketTrendPainter extends CustomPainter {
  _MarketTrendPainter({required this.points});

  final List<MarketHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 0.0000001 ? 1.0 : (maxV - minV);

    final axis = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axis,
    );

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? 0.0
          : size.width * (i / (points.length - 1));
      final y =
          size.height - ((points[i].value - minV) / span) * (size.height - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = AppColors.info
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MarketTrendPainter oldDelegate) =>
      oldDelegate.points != points;
}
