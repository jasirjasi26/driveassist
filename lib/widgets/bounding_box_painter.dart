import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/vehicle.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectedVehicle> detections;
  final double safeDistance;

  BoundingBoxPainter({
    required this.detections,
    required this.safeDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var vehicle in detections) {
      // Scale normalized box to current canvas size
      final rect = Rect.fromLTRB(
        vehicle.boundingBox.left * size.width,
        vehicle.boundingBox.top * size.height,
        vehicle.boundingBox.right * size.width,
        vehicle.boundingBox.bottom * size.height,
      );

      // Determine safety status color
      Color alertColor = AppTheme.electricTeal;
      if (vehicle.distance < safeDistance) {
        alertColor = AppTheme.neonCrimson;
      } else if (vehicle.distance < safeDistance * 1.5) {
        alertColor = AppTheme.warningOrange;
      }

      // 1. Draw glowing background rect
      final bgPaint = Paint()
        ..color = alertColor.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);

      // 2. Draw subtle border line
      final borderPaint = Paint()
        ..color = alertColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(rect, borderPaint);

      // 3. Draw heavy corner brackets (high-tech feel)
      final bracketPaint = Paint()
        ..color = alertColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      const bracketLength = 20.0;
      
      // Top Left Corner
      canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(bracketLength, 0), bracketPaint);
      canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, bracketLength), bracketPaint);
      
      // Top Right Corner
      canvas.drawLine(rect.topRight, rect.topRight + const Offset(-bracketLength, 0), bracketPaint);
      canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, bracketLength), bracketPaint);
      
      // Bottom Left Corner
      canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(bracketLength, 0), bracketPaint);
      canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -bracketLength), bracketPaint);
      
      // Bottom Right Corner
      canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-bracketLength, 0), bracketPaint);
      canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -bracketLength), bracketPaint);

      // 4. Draw Label Tag (e.g. CAR [94%] 22m)
      final textSpan = TextSpan(
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        text: '${vehicle.label.toUpperCase()} [${(vehicle.confidence * 100).toStringAsFixed(0)}%]  ${vehicle.distance.toStringAsFixed(1)}m',
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Tag Background Container
      final tagRect = Rect.fromLTRB(
        rect.left,
        rect.top - textPainter.height - 8,
        rect.left + textPainter.width + 12,
        rect.top,
      );

      final tagPaint = Paint()
        ..color = alertColor
        ..style = PaintingStyle.fill;

      // Draw tag container with top-rounded corners
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          tagRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        tagPaint,
      );

      // Offset text to center of tag container
      textPainter.paint(canvas, Offset(rect.left + 6, rect.top - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.safeDistance != safeDistance;
  }
}
