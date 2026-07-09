import 'package:flutter_test/flutter_test.dart';
import 'package:sampleapp/core/utils/adas_calculator.dart';

void main() {
  group('ADAS Safe Distance Calculations (2-Second Rule)', () {
    test('Should return minimum safe distance at zero speed', () {
      final safeDistance = AdasCalculator.calculateSafeDistance(0.0);
      expect(safeDistance, equals(5.0));
    });

    test('Should calculate safe distance at 20 km/h (~11.1 meters)', () {
      final safeDistance = AdasCalculator.calculateSafeDistance(20.0);
      // (20 / 3.6) * 2 = 11.11
      expect(safeDistance, closeTo(11.11, 0.1));
    });

    test('Should calculate safe distance at 60 km/h (~33.3 meters)', () {
      final safeDistance = AdasCalculator.calculateSafeDistance(60.0);
      // (60 / 3.6) * 2 = 33.33
      expect(safeDistance, closeTo(33.33, 0.1));
    });

    test('Should calculate safe distance at 80 km/h (~44.4 meters)', () {
      final safeDistance = AdasCalculator.calculateSafeDistance(80.0);
      // (80 / 3.6) * 2 = 44.44
      expect(safeDistance, closeTo(44.44, 0.1));
    });
  });

  group('ADAS Single Camera Distance Estimation', () {
    test('Should return 100 meters if box height is zero or invalid', () {
      final distance = AdasCalculator.estimateDistance(0.0, 'car');
      expect(distance, equals(100.0));
    });

    test('Should estimate distance correctly for a standard passenger car', () {
      // Distance = (focalFactor * carHeight) / relativeHeight = (2.4 * 1.5) / 0.1 = 36.0m
      final distance = AdasCalculator.estimateDistance(0.1, 'car');
      expect(distance, equals(36.0));
    });

    test('Should estimate distance correctly for a truck (larger physical height)', () {
      // Distance = (focalFactor * truckHeight) / relativeHeight = (2.4 * 3.2) / 0.1 = 76.8m
      final distance = AdasCalculator.estimateDistance(0.1, 'truck');
      expect(distance, equals(76.8));
    });

    test('Should clamp estimated distance to realistic boundaries', () {
      // Very close: (2.4 * 1.5) / 0.99 = 3.6m
      final closeDist = AdasCalculator.estimateDistance(0.99, 'car');
      expect(closeDist, equals(3.6));

      // Very far: (2.4 * 1.5) / 0.001 = 3600m -> clamped to 120m limit
      final farDist = AdasCalculator.estimateDistance(0.001, 'car');
      expect(farDist, equals(120.0));
    });
  });

  group('ADAS Driving Score Deductions', () {
    test('Should return 100 points for a perfect drive with zero incidents', () {
      final score = AdasCalculator.calculateScore(
        hardBrakingCount: 0,
        tailgatingDurationSeconds: 0,
        overspeedDurationSeconds: 0,
        suddenAccelerationCount: 0,
        laneDepartureCount: 0,
      );
      expect(score, equals(100));
    });

    test('Should deduct points accurately for various incidents', () {
      final score = AdasCalculator.calculateScore(
        hardBrakingCount: 1, // -8 points
        tailgatingDurationSeconds: 15, // -6 points (3 groups of 5 seconds)
        overspeedDurationSeconds: 20, // -6 points (2 groups of 10 seconds)
        suddenAccelerationCount: 2, // -10 points
        laneDepartureCount: 3, // -12 points
      );
      // Total score: 100 - 8 - 6 - 6 - 10 - 12 = 58
      expect(score, equals(58));
    });

    test('Should clamp driving score to a minimum of 0', () {
      final score = AdasCalculator.calculateScore(
        hardBrakingCount: 20,
        tailgatingDurationSeconds: 1000,
        overspeedDurationSeconds: 1000,
        suddenAccelerationCount: 20,
        laneDepartureCount: 20,
      );
      expect(score, equals(0));
    });
  });
}
