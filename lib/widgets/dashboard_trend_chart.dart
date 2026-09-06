import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/dashboard.dart';
import '../core/utils/formatters.dart';

/// Simple dual-series bar chart without extra packages.
class DashboardTrendChart extends StatelessWidget {
  const DashboardTrendChart({super.key, required this.points});

  final List<DashboardTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('No trend data', style: AppTextStyles.bodySmall),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _TrendPainter(points: points),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(AppColors.info, 'Sales'),
            const SizedBox(width: 16),
            _legendDot(AppColors.success, 'Profit'),
            const Spacer(),
            Text(
              '${Formatters.date(points.first.day)} → ${Formatters.date(points.last.day)}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points});

  final List<DashboardTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = points.fold<double>(0, (max, p) {
      final local = p.salesTotal > p.profitTotal ? p.salesTotal : p.profitTotal;
      return local > max ? local : max;
    });
    final chartMax = maxValue <= 0 ? 1.0 : maxValue;

    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    final count = points.length;
    final slot = size.width / count;
    final barWidth = (slot * 0.28).clamp(2.0, 14.0);

    for (var i = 0; i < count; i++) {
      final point = points[i];
      final center = slot * i + slot / 2;
      final salesH = (point.salesTotal / chartMax) * (size.height - 8);
      final profitH = (point.profitTotal / chartMax) * (size.height - 8);

      final salesRect = Rect.fromLTWH(
        center - barWidth - 2,
        size.height - salesH,
        barWidth,
        salesH,
      );
      final profitRect = Rect.fromLTWH(
        center + 2,
        size.height - profitH,
        barWidth,
        profitH,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(salesRect, const Radius.circular(2)),
        Paint()..color = AppColors.info,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(profitRect, const Radius.circular(2)),
        Paint()..color = AppColors.success,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}
