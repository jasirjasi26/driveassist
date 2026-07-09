import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SpeedometerGauge extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final int limit;
  final bool isOverspeeding;
  final String unit;

  const SpeedometerGauge({
    Key? key,
    required this.speed,
    this.maxSpeed = 160.0,
    required this.limit,
    required this.isOverspeeding,
    this.unit = 'km/h',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeColor = isOverspeeding ? AppTheme.neonCrimson : AppTheme.electricTeal;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Radial Painter
        CustomPaint(
          size: const Size(200, 200),
          painter: _SpeedometerPainter(
            speed: speed,
            maxSpeed: maxSpeed,
            color: activeColor,
          ),
        ),
        // Central Speed Value
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: activeColor,
                shadows: [
                  Shadow(
                    color: activeColor.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Text(speed.toStringAsFixed(0)),
            ),
            Text(
              unit.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOverspeeding
                    ? AppTheme.neonCrimson.withOpacity(0.2)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverspeeding
                      ? AppTheme.neonCrimson
                      : Colors.white.withOpacity(0.15),
                  width: 0.8,
                ),
              ),
              child: Text(
                'LIMIT: $limit',
                style: TextStyle(
                  fontSize: 10,
                  color: isOverspeeding ? AppTheme.neonCrimson : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color color;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paints
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw background track arc (270 degrees total, centered at bottom)
    // Start angle: 135 deg (3*pi/4), Sweep angle: 270 deg (3*pi/2)
    const startAngle = 3 * pi / 4;
    const sweepAngle = 3 * pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw active progress arc
    double speedFraction = (speed / maxSpeed).clamp(0.0, 1.0);
    double activeSweepAngle = sweepAngle * speedFraction;

    // Glowing shadow for progress arc
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      activeSweepAngle,
      false,
      glowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      activeSweepAngle,
      false,
      progressPaint,
    );

    // Draw ticks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i <= 8; i++) {
      double angle = startAngle + (sweepAngle * (i / 8));
      double startRadius = radius - 20;
      double endRadius = radius - 25;

      Offset startOffset = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );
      Offset endOffset = Offset(
        center.dx + endRadius * cos(angle),
        center.dy + endRadius * sin(angle),
      );

      canvas.drawLine(startOffset, endOffset, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.color != color;
  }
}
