import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;
  
  // Callbacks for ADAS events
  Function()? onHardBraking;
  Function()? onSuddenAcceleration;

  // Thresholds in m/s^2 (excluding gravity)
  double hardBrakingThreshold = 3.2; // roughly ~0.33g
  double suddenAccelerationThreshold = 2.6; // roughly ~0.26g

  // Simple low-pass filter / debouncer
  DateTime _lastBrakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastAccelTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _cooldownMs = 3000; // 3 seconds event cooldown

  /// Start listening to accelerometer updates.
  void startMonitoring() {
    _sensorSubscription?.cancel();
    
    _sensorSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Calculate overall movement magnitude in 3D space (excluding gravity)
      // Since userAccelerometer has gravity subtracted, any reading is user-induced force
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      final now = DateTime.now();

      // Check dominant axis for braking vs acceleration
      // Typically, in a standard dashboard mount:
      // - Z-axis is perpendicular to the screen (forward/backward)
      // - Y-axis is vertical (up/down)
      // - X-axis is lateral (left/right)
      // Sudden braking results in the phone pitching forward (high Z and Y forces).
      // We look for significant shifts.
      
      if (magnitude > hardBrakingThreshold) {
        // Distinguish between braking (deceleration) and acceleration.
        // Braking creates a positive force pushing forward (positive Z force in portrait mount).
        // For standard mount logic:
        if (event.z > 1.5 || event.y < -1.5) {
          if (now.difference(_lastBrakeTime).inMilliseconds > _cooldownMs) {
            _lastBrakeTime = now;
            onHardBraking?.call();
          }
        } else if (event.z < -1.5 || event.y > 1.5) {
          if (now.difference(_lastAccelTime).inMilliseconds > _cooldownMs) {
            _lastAccelTime = now;
            onSuddenAcceleration?.call();
          }
        }
      }
    });
  }

  /// Stop listening to accelerometer updates.
  void stopMonitoring() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }
}
