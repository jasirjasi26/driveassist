import 'dart:math';

class AdasCalculator {
  /// Calculates the safe stopping distance using the 2-second rule.
  /// Formula: Safe Distance = Current Speed (in m/s) * 2 seconds
  static double calculateSafeDistance(double speedKmh) {
    if (speedKmh <= 0) return 5.0; // Minimum default safe distance
    double speedMps = speedKmh / 3.6;
    return speedMps * 2.0;
  }

  /// Estimates the distance to a vehicle from a single camera using the bounding box height.
  /// Uses a simplified pinhole camera model: Distance = (FocalLength * RealHeight) / ImageBBoxHeight.
  /// [relativeHeight] is the normalized height of the bounding box (0.0 to 1.0).
  static double estimateDistance(double relativeHeight, String label) {
    // Prevent division by zero
    if (relativeHeight <= 0) return 100.0;

    // Approximated physical heights of vehicles in meters
    double physicalHeight = 1.5; // Default for 'car'
    switch (label.toLowerCase()) {
      case 'truck':
        physicalHeight = 3.2;
        break;
      case 'bus':
        physicalHeight = 3.0;
        break;
      case 'bike':
      case 'motorbike':
      case 'bicycle':
        physicalHeight = 1.2;
        break;
    }

    // Focal length factor calibrated for standard phone cameras in vertical mounts
    // Distance = (FocalFactor * PhysicalHeight) / RelativeHeight
    const double focalFactor = 2.4;
    double estimated = (focalFactor * physicalHeight) / relativeHeight;

    // Clamp values to realistic ranges (2m to 120m)
    return double.parse(estimated.clamp(2.0, 120.0).toStringAsFixed(1));
  }

  /// Calculates driving score based on alert events over a trip.
  /// Starts at 100 and deducts points based on the frequency and severity of infractions.
  static int calculateScore({
    required int hardBrakingCount,
    required int tailgatingDurationSeconds,
    required int overspeedDurationSeconds,
    required int suddenAccelerationCount,
    required int laneDepartureCount,
  }) {
    int score = 100;

    // Deduct 8 points per hard braking event
    score -= hardBrakingCount * 8;

    // Deduct 2 points for every 5 cumulative seconds of tailgating
    score -= (tailgatingDurationSeconds ~/ 5) * 2;

    // Deduct 3 points for every 10 cumulative seconds of overspeeding
    score -= (overspeedDurationSeconds ~/ 10) * 3;

    // Deduct 5 points per sudden acceleration event
    score -= suddenAccelerationCount * 5;

    // Deduct 4 points per lane departure warning
    score -= laneDepartureCount * 4;

    return max(0, score);
  }
}
