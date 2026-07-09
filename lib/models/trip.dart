import 'package:hive/hive.dart';
import 'warning.dart';

@HiveType(typeId: 1)
class Trip extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double distance; // in kilometers

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final double avgSpeed; // in km/h

  @HiveField(5)
  final double maxSpeed; // in km/h

  @HiveField(6)
  final int score; // 0-100

  @HiveField(7)
  final int hardBrakingCount;

  @HiveField(8)
  final int suddenAccelerationCount;

  @HiveField(9)
  final int tailgatingSeconds;

  @HiveField(10)
  final int overspeedSeconds;

  @HiveField(11)
  final int laneDepartureCount;

  @HiveField(12)
  final List<Warning> warnings;

  Trip({
    required this.id,
    required this.date,
    required this.distance,
    required this.durationSeconds,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.score,
    required this.hardBrakingCount,
    required this.suddenAccelerationCount,
    required this.tailgatingSeconds,
    required this.overspeedSeconds,
    required this.laneDepartureCount,
    required this.warnings,
  });

  // Manual serialization to/from Map for safe Storage fallback
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'distance': distance,
      'durationSeconds': durationSeconds,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'score': score,
      'hardBrakingCount': hardBrakingCount,
      'suddenAccelerationCount': suddenAccelerationCount,
      'tailgatingSeconds': tailgatingSeconds,
      'overspeedSeconds': overspeedSeconds,
      'laneDepartureCount': laneDepartureCount,
      'warnings': warnings.map((w) => w.toMap()).toList(),
    };
  }

  factory Trip.fromMap(Map<dynamic, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      distance: (map['distance'] as num).toDouble(),
      durationSeconds: map['durationSeconds'] as int,
      avgSpeed: (map['avgSpeed'] as num).toDouble(),
      maxSpeed: (map['maxSpeed'] as num).toDouble(),
      score: map['score'] as int,
      hardBrakingCount: map['hardBrakingCount'] as int,
      suddenAccelerationCount: map['suddenAccelerationCount'] as int,
      tailgatingSeconds: map['tailgatingSeconds'] as int,
      overspeedSeconds: map['overspeedSeconds'] as int,
      laneDepartureCount: map['laneDepartureCount'] as int,
      warnings: (map['warnings'] as List)
          .map((w) => Warning.fromMap(w as Map))
          .toList(),
    );
  }
}

// Manual Hive Adapter for Trip
class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 1;

  @override
  Trip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trip(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      distance: fields[2] as double,
      durationSeconds: fields[3] as int,
      avgSpeed: fields[4] as double,
      maxSpeed: fields[5] as double,
      score: fields[6] as int,
      hardBrakingCount: fields[7] as int,
      suddenAccelerationCount: fields[8] as int,
      tailgatingSeconds: fields[9] as int,
      overspeedSeconds: fields[10] as int,
      laneDepartureCount: fields[11] as int,
      warnings: (fields[12] as List).cast<Warning>(),
    );
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.distance)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.avgSpeed)
      ..writeByte(5)
      ..write(obj.maxSpeed)
      ..writeByte(6)
      ..write(obj.score)
      ..writeByte(7)
      ..write(obj.hardBrakingCount)
      ..writeByte(8)
      ..write(obj.suddenAccelerationCount)
      ..writeByte(9)
      ..write(obj.tailgatingSeconds)
      ..writeByte(10)
      ..write(obj.overspeedSeconds)
      ..writeByte(11)
      ..write(obj.laneDepartureCount)
      ..writeByte(12)
      ..write(obj.warnings);
  }
}

// Manual Hive Adapter for Warning
class WarningAdapter extends TypeAdapter<Warning> {
  @override
  final int typeId = 2;

  @override
  Warning read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Warning(
      type: fields[0] as String,
      message: fields[1] as String,
      timestamp: fields[2] as DateTime,
      speed: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Warning obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.speed);
  }
}
