import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LanePainter extends CustomPainter {
  final List<Offset> leftLane;
  final List<Offset> rightLane;
  final bool isLaneDeparture;
  final double driftOffset;

  LanePainter({
    required this.leftLane,
    required this.rightLane,
    required this.isLaneDeparture,
    required this.driftOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (leftLane.isEmpty || rightLane.isEmpty) return;

    // Convert normalized offsets to pixel offsets
    List<Offset> leftPoints = leftLane
        .map((o) => Offset(o.dx * size.width, o.dy * size.height))
        .toList();
    List<Offset> rightPoints = rightLane
        .map((o) => Offset(o.dx * size.width, o.dy * size.height))
        .toList();

    // Determine color scheme based on departure
    Color laneColor = AppTheme.electricTeal;
    if (isLaneDeparture) {
      laneColor = AppTheme.warningOrange;
    }

    // 1. Draw glowing drivable lane corridor (AR highway green/cyan overlay)
    final corridorPath = Path();
    corridorPath.moveTo(leftPoints.first.dx, leftPoints.first.dy);
    for (int i = 1; i < leftPoints.length; i++) {
      corridorPath.lineTo(leftPoints[i].dx, leftPoints[i].dy);
    }
    // Cross over to right lane horizon and descend
    corridorPath.lineTo(rightPoints.last.dx, rightPoints.last.dy);
    for (int i = rightPoints.length - 2; i >= 0; i--) {
      corridorPath.lineTo(rightPoints[i].dx, rightPoints[i].dy);
    }
    corridorPath.close();

    final corridorPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: isLaneDeparture
            ? [
                AppTheme.warningOrange.withOpacity(0.25),
                AppTheme.warningOrange.withOpacity(0.02)
              ]
            : [
                AppTheme.electricTeal.withOpacity(0.20),
                AppTheme.electricTeal.withOpacity(0.01)
              ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTRB(
          0, leftPoints.last.dy, size.width, leftPoints.first.dy));

    canvas.drawPath(corridorPath, corridorPaint);

    // 2. Draw solid lane marker lines
    final linePaint = Paint()
      ..color = laneColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = laneColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Draw Left Lane
    final leftPath = Path();
    leftPath.moveTo(leftPoints.first.dx, leftPoints.first.dy);
    for (int i = 1; i < leftPoints.length; i++) {
      leftPath.lineTo(leftPoints[i].dx, leftPoints[i].dy);
    }
    canvas.drawPath(leftPath, glowPaint);
    canvas.drawPath(leftPath, linePaint);

    // Draw Right Lane
    final rightPath = Path();
    rightPath.moveTo(rightPoints.first.dx, rightPoints.first.dy);
    for (int i = 1; i < rightPoints.length; i++) {
      rightPath.lineTo(rightPoints[i].dx, rightPoints[i].dy);
    }
    canvas.drawPath(rightPath, glowPaint);
    canvas.drawPath(rightPath, linePaint);

    // 3. Draw hazard indicator arrow in center if departing
    if (isLaneDeparture) {
      final arrowPaint = Paint()
        ..color = AppTheme.warningOrange
        ..style = PaintingStyle.fill;

      final arrowPath = Path();
      double arrowCenterX = size.width / 2;
      double arrowCenterY = size.height * 0.78;
      double arrowSize = 18.0;

      // Point arrow left or right depending on drift
      if (driftOffset < 0) {
        // Drifting Left: draw arrow pointing right to steer back
        arrowPath.moveTo(arrowCenterX - arrowSize, arrowCenterY);
        arrowPath.lineTo(arrowCenterX, arrowCenterY - arrowSize);
        arrowPath.lineTo(arrowCenterX, arrowCenterY - arrowSize / 2);
        arrowPath.lineTo(
            arrowCenterX + arrowSize, arrowCenterY - arrowSize / 2);
        arrowPath.lineTo(
            arrowCenterX + arrowSize, arrowCenterY + arrowSize / 2);
        arrowPath.lineTo(arrowCenterX, arrowCenterY + arrowSize / 2);
        arrowPath.lineTo(arrowCenterX, arrowCenterY + arrowSize);
      } else {
        // Drifting Right: draw arrow pointing left
        arrowPath.moveTo(arrowCenterX + arrowSize, arrowCenterY);
        arrowPath.lineTo(arrowCenterX, arrowCenterY - arrowSize);
        arrowPath.lineTo(arrowCenterX, arrowCenterY - arrowSize / 2);
        arrowPath.lineTo(
            arrowCenterX - arrowSize, arrowCenterY - arrowSize / 2);
        arrowPath.lineTo(
            arrowCenterX - arrowSize, arrowCenterY + arrowSize / 2);
        arrowPath.lineTo(arrowCenterX, arrowCenterY + arrowSize / 2);
        arrowPath.lineTo(arrowCenterX, arrowCenterY + arrowSize);
      }
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LanePainter oldDelegate) {
    return oldDelegate.leftLane != leftLane ||
        oldDelegate.rightLane != rightLane ||
        oldDelegate.isLaneDeparture != isLaneDeparture ||
        oldDelegate.driftOffset != driftOffset;
  }
}
