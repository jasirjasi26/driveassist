import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Warning {
  @HiveField(0)
  final String type; // 'tailgating', 'overspeed', 'lane_departure', 'hard_braking'

  @HiveField(1)
  final String message;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double speed; // Speed in km/h at the time of warning

  Warning({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.speed,
  });

  // Manual Hive serialization / deserialization helpers to avoid build_runner dependency
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }

  factory Warning.fromMap(Map<dynamic, dynamic> map) {
    return Warning(
      type: map['type'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      speed: (map['speed'] as num).toDouble(),
    );
  }
}
