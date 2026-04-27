import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Animated revenue sparkline for dashboard stat cards
/// Shows mini chart of daily revenue trend
class RevenueSparkline extends StatelessWidget {
  final List<double> data;
  final double height;
  final Color? lineColor;
  final Color? fillColor;
  final bool showDots;

  const RevenueSparkline({
    super.key,
    required this.data,
    this.height = 40,
    this.lineColor,
    this.fillColor,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: SparklinePainter(
          data: data,
          lineColor: lineColor ?? AppColors.primary,
          fillColor: fillColor ?? AppColors.primary.withValues(alpha: 0.1),
          showDots: showDots,
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final bool showDots;

  SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = range == 0
          ? size.height / 2
          : size.height - ((data[i] - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Draw fill area
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      // Smooth curve between points
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw dots if enabled
    if (showDots) {
      for (final point in points) {
        canvas.drawCircle(
          point,
          3,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
