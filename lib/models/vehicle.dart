import 'package:flutter/material.dart';

class DetectedVehicle {
  final String id;
  final String label; // 'car', 'truck', 'bus', 'bike'
  final double confidence;
  final Rect boundingBox; // Normalized bounding box coordinates (0.0 to 1.0)
  final double distance; // Estimated distance in meters
  final double relativeSpeed; // Estimated relative speed in km/h (+ means moving away, - means approaching)

  DetectedVehicle({
    required this.id,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.distance,
    this.relativeSpeed = 0.0,
  });

  DetectedVehicle copyWith({
    String? id,
    String? label,
    double? confidence,
    Rect? boundingBox,
    double? distance,
    double? relativeSpeed,
  }) {
    return DetectedVehicle(
      id: id ?? this.id,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      distance: distance ?? this.distance,
      relativeSpeed: relativeSpeed ?? this.relativeSpeed,
    );
  }
}
