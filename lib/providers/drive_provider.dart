import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/utils/adas_calculator.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../models/warning.dart';
import '../services/detector_service.dart';
import '../services/gps_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class DriveProvider extends ChangeNotifier {
  // Services
  final GpsService _gpsService = GpsService();
  final SensorService _sensorService = SensorService();
  final DetectorService _detectorService = DetectorService();
  final TtsService _ttsService = TtsService();
  final StorageService _storageService = StorageService();

  DetectorService get detectorService => _detectorService;

  // Active Trip State Flags
  bool _isTripActive = false;
  bool get isTripActive => _isTripActive;

  // Active Speedometer Data
  double _currentSpeed = 0.0; // km/h
  double _maxSpeed = 0.0;
  double _avgSpeed = 0.0;
  double _gpsAccuracy = 0.0; // meters
  double _distanceTraveled = 0.0; // km
  int _elapsedSeconds = 0;

  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get avgSpeed => _avgSpeed;
  double get gpsAccuracy => _gpsAccuracy;
  double get distanceTraveled => _distanceTraveled;
  int get elapsedSeconds => _elapsedSeconds;

  // Active ADAS Safety metrics
  double _leadVehicleDistance = 150.0; // meters (start far)
  double _safeDistance = 5.0; // meters
  String _leadVehicleLabel = "None";
  double _laneOffset = 0.0; // 0.0 center, -1.0 left drift, +1.0 right drift
  double _detectorFps = 0.0;

  double get leadVehicleDistance => _leadVehicleDistance;
  double get safeDistance => _safeDistance;
  String get leadVehicleLabel => _leadVehicleLabel;
  double get laneOffset => _laneOffset;
  double get detectorFps => _detectorFps;

  // Alert Warnings State
  bool _isTailgating = false;
  bool _isOverspeeding = false;
  bool _isLaneDeparture = false;

  bool get isTailgating => _isTailgating;
  bool get isOverspeeding => _isOverspeeding;
  bool get isLaneDeparture => _isLaneDeparture;

  // Scoring Metrics Accumulator
  int _hardBrakingCount = 0;
  int _suddenAccelerationCount = 0;
  int _tailgatingDurationSeconds = 0;
  int _overspeedDurationSeconds = 0;
  int _laneDepartureCount = 0;
  int _drivingScore = 100;

  int get hardBrakingCount => _hardBrakingCount;
  int get suddenAccelerationCount => _suddenAccelerationCount;
  int get tailgatingDurationSeconds => _tailgatingDurationSeconds;
  int get overspeedDurationSeconds => _overspeedDurationSeconds;
  int get laneDepartureCount => _laneDepartureCount;
  int get drivingScore => _drivingScore;

  // Warning lists during trip
  final List<Warning> _tripWarnings = [];
  List<Warning> get tripWarnings => _tripWarnings;

  // Stream Subscriptions
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<List<DetectedVehicle>>? _detectionSubscription;
  StreamSubscription<Map<String, List<Offset>>>? _laneSubscription;
  StreamSubscription<double>? _fpsSubscription;

  // Active timers
  Timer? _tripTimer;
  Timer? _overspeedTimer;
  DateTime? _lastTrafficMoveSpeakTime;

  // Traffic move helper flags
  bool _wasLeadVehicleStopped = false;

  // Speed Limit threshold cache (read from settings provider in dashboard)
  int _speedLimitThreshold = 80;

  /// Start the ADAS Drive Assist mode.
  Future<void> startTrip(int speedLimit) async {
    if (_isTripActive) return;
    _speedLimitThreshold = speedLimit;
    _isTripActive = true;

    // Reset session trackers
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _avgSpeed = 0.0;
    _gpsAccuracy = 0.0;
    _distanceTraveled = 0.0;
    _elapsedSeconds = 0;

    _leadVehicleDistance = 150.0;
    _safeDistance = 5.0;
    _leadVehicleLabel = "None";
    _laneOffset = 0.0;

    _isTailgating = false;
    _isOverspeeding = false;
    _isLaneDeparture = false;

    _hardBrakingCount = 0;
    _suddenAccelerationCount = 0;
    _tailgatingDurationSeconds = 0;
    _overspeedDurationSeconds = 0;
    _laneDepartureCount = 0;
    _drivingScore = 100;
    _tripWarnings.clear();
    _wasLeadVehicleStopped = false;

    // Wake lock to keep screen awake during drive
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    // 1. Initialise TTS & Speak Start Warning
    await _ttsService.init();
    await _ttsService.speak("Journey started. Drive carefully.");

    // 2. Start GPS Speed streaming
    await _gpsService.checkGpsAvailability();
    _gpsSubscription =
        _gpsService.startSpeedStream().listen((Position position) {
      _currentSpeed = _gpsService.getSpeedKmh(position);
      _gpsAccuracy = position.accuracy;
      if (_currentSpeed > _maxSpeed) {
        _maxSpeed = _currentSpeed;
      }
      _checkOverspeedState();
      notifyListeners();
    }, onError: (e) {
      print("GPS subscription error: $e");
    });

    // 3. Start Accelerometer Sensor monitoring
    _sensorService.onHardBraking = () => _handleBrakingEvent(true);
    _sensorService.onSuddenAcceleration = () => _handleBrakingEvent(false);
    _sensorService.startMonitoring();

    // 4. Start ML AI Object Detection
    _detectorService.startDetection();
    _fpsSubscription = _detectorService.fpsStream.listen((fps) {
      _detectorFps = fps;
      notifyListeners();
    });

    _detectionSubscription =
        _detectorService.detectionStream.listen((vehicles) {
      _processDetections(vehicles);
    });

    _laneSubscription = _detectorService.laneStream.listen((lanes) {
      _processLanes(lanes);
    });

    // 5. Start Trip Clock Timer (1Hz ticks)
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickTripStats();
    });

    notifyListeners();
  }

  /// Stop and finalize the ADAS Drive Assist mode.
  Future<Trip?> stopTrip() async {
    if (!_isTripActive) return null;
    _isTripActive = false;

    _tripTimer?.cancel();
    _tripTimer = null;
    _overspeedTimer?.cancel();
    _overspeedTimer = null;

    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _gpsService.stopSpeedStream();

    _sensorService.stopMonitoring();
    _detectorService.stopDetection();

    _detectionSubscription?.cancel();
    _detectionSubscription = null;
    _laneSubscription?.cancel();
    _laneSubscription = null;
    _fpsSubscription?.cancel();
    _fpsSubscription = null;

    // Wake lock release
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    await _ttsService.speak("Journey completed.");

    // Build the final Trip entity
    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      distance: _distanceTraveled,
      durationSeconds: _elapsedSeconds,
      avgSpeed: _avgSpeed,
      maxSpeed: _maxSpeed,
      score: _drivingScore,
      hardBrakingCount: _hardBrakingCount,
      suddenAccelerationCount: _suddenAccelerationCount,
      tailgatingSeconds: _tailgatingDurationSeconds,
      overspeedSeconds: _overspeedDurationSeconds,
      laneDepartureCount: _laneDepartureCount,
      warnings: List.from(_tripWarnings),
    );

    // Persist trip to Database
    await _storageService.saveTrip(trip);

    notifyListeners();
    return trip;
  }

  // --- SAFETY ENGINE HELPERS ---

  /// Handles Accelerometer events (Hard Braking / Sudden Acceleration)
  void _handleBrakingEvent(bool isBrake) {
    if (!_isTripActive) return;

    if (isBrake) {
      _hardBrakingCount++;
      _addWarning('hard_braking', 'Hard braking detected');
      _ttsService.speak("Hard braking detected. Maintain control.",
          cooldownSeconds: 3);
      _triggerVibration();
    } else {
      _suddenAccelerationCount++;
      _addWarning('sudden_acceleration', 'Sudden acceleration detected');
      _ttsService.speak("Sudden acceleration", cooldownSeconds: 3);
    }
    _recalculateScore();
    notifyListeners();
  }

  /// Evaluates detections output from Live ML/Simulator
  void _processDetections(List<DetectedVehicle> vehicles) {
    if (vehicles.isEmpty) {
      _leadVehicleDistance = 150.0;
      _leadVehicleLabel = "None";
      _isTailgating = false;
      notifyListeners();
      return;
    }

    // Find the lead vehicle (closest vehicle detected)
    DetectedVehicle lead = vehicles.first;
    for (var v in vehicles) {
      if (v.distance < lead.distance) {
        lead = v;
      }
    }

    _leadVehicleDistance = lead.distance;
    _leadVehicleLabel = lead.label;

    // Safe Distance calculation
    _safeDistance = AdasCalculator.calculateSafeDistance(_currentSpeed);

    // Tailgating detection
    if (_leadVehicleDistance < _safeDistance && _currentSpeed > 5.0) {
      if (!_isTailgating) {
        _isTailgating = true;
        _addWarning('tailgating', 'Tailgating lead ${lead.label}');
        _ttsService.speak("Maintain safe distance", cooldownSeconds: 5);
        _triggerVibration();
      }
    } else {
      _isTailgating = false;
    }

    // --- Traffic Moving Detection ---
    // If we are stopped behind a car (< 10m) and it starts moving away (> 10m)
    if (_currentSpeed <= 5.0 && _leadVehicleDistance < 10.0) {
      _wasLeadVehicleStopped = true;
    }

    if (_wasLeadVehicleStopped &&
        _currentSpeed <= 10.0 &&
        _leadVehicleDistance > 14.0) {
      // Vehicle in front is accelerating away
      final now = DateTime.now();
      if (_lastTrafficMoveSpeakTime == null ||
          now.difference(_lastTrafficMoveSpeakTime!).inSeconds > 15) {
        _lastTrafficMoveSpeakTime = now;
        _ttsService
            .speak("Traffic ahead is moving. You may accelerate safely.");
        _wasLeadVehicleStopped = false;
      }
    }


    notifyListeners();
  }

  /// Processes lane coordinate outputs for lane departures
  void _processLanes(Map<String, List<Offset>> lanes) {
    // Estimating lane offset drift from coordinates.
    // In our Simulator: left/right lanes shift horizontal offset via _roadOffset
    // We check DetectorService's current offset simulation parameter
    // Or approximate from bottom offset.
    // Let's grab the actual simulated offset or read from the bottom offsets of lane lines:
    // If leftLane bottom X coordinate is drifted too far to the right, we are departing left.
    // We can use a direct mapping:
    // Simulator provides leftLane bottom Offset around X = 0.2, rightLane around X = 0.8.
    // Let's check laneOffset threshold:
    // Since DetectorService handles this in its timer loop, we retrieve drift directly.

    // Grab relative lane drift offset (X coordinate relative drift)
    // Left lane departure: offset < -0.35, Right lane departure: offset > 0.35
    double driftOffset = 0.0;
    final leftPoints = lanes['left'];
    final rightPoints = lanes['right'];

    if (leftPoints != null &&
        leftPoints.isNotEmpty &&
        rightPoints != null &&
        rightPoints.isNotEmpty) {
      // Measure drift: average horizontal shift of the lane baselines
      double baselineLeft = leftPoints.first.dx;
      double baselineRight = rightPoints.first.dx;
      // Normal baseline centers: left = 0.20, right = 0.80. Center is 0.5
      double currentCenter = (baselineLeft + baselineRight) / 2.0;
      driftOffset = (currentCenter - 0.5) * 2.5; // Scale drift offset
    }

    _laneOffset = driftOffset;

    // Trigger Warning if drift exceeds 0.35
    if (driftOffset.abs() > 0.35 && _currentSpeed > 25.0) {
      if (!_isLaneDeparture) {
        _isLaneDeparture = true;
        _laneDepartureCount++;
        _addWarning('lane_departure', 'Lane Departure Alert');
        _ttsService.speak("Lane departure warning", cooldownSeconds: 5);
        _triggerVibration();
        _recalculateScore();
      }
    } else {
      _isLaneDeparture = false;
    }

    notifyListeners();
  }

  /// Checks overspeed state against limits
  void _checkOverspeedState() {
    if (_currentSpeed > _speedLimitThreshold) {
      if (!_isOverspeeding) {
        _isOverspeeding = true;
        _addWarning(
            'overspeed', 'Exceeded Speed Limit ($_speedLimitThreshold km/h)');
        _triggerOverspeedTtsLoop();
      }
    } else {
      _isOverspeeding = false;
      _overspeedTimer?.cancel();
      _overspeedTimer = null;
    }
  }

  /// Triggers a repetitive TTS overspeed warning every 10 seconds
  void _triggerOverspeedTtsLoop() {
    _overspeedTimer?.cancel();
    _ttsService.speak("Reduce Speed");

    _overspeedTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isOverspeeding && _isTripActive) {
        _ttsService.speak("Reduce Speed");
      } else {
        timer.cancel();
      }
    });
  }

  /// Helper to record warning events
  void _addWarning(String type, String message) {
    final warning = Warning(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      speed: _currentSpeed,
    );
    _tripWarnings.add(warning);
    notifyListeners();
  }

  /// Recalculates the user driving score based on current parameters
  void _recalculateScore() {
    _drivingScore = AdasCalculator.calculateScore(
      hardBrakingCount: _hardBrakingCount,
      tailgatingDurationSeconds: _tailgatingDurationSeconds,
      overspeedDurationSeconds: _overspeedDurationSeconds,
      suddenAccelerationCount: _suddenAccelerationCount,
      laneDepartureCount: _laneDepartureCount,
    );
  }

  /// Integrates travel statistics second-by-second
  void _tickTripStats() {
    _elapsedSeconds++;

    // Integrate distance: speed in km/h to distance in km:
    // Speed km/h / 3600 = distance in km per second
    _distanceTraveled += _currentSpeed / 3600.0;

    // Calculate Average Speed
    if (_elapsedSeconds > 0) {
      // Simple speed accumulation
      double totalSpeedSum =
          (_avgSpeed * (_elapsedSeconds - 1)) + _currentSpeed;
      _avgSpeed = totalSpeedSum / _elapsedSeconds;
    }

    // Accumulate duration-based penalties
    if (_isTailgating) {
      _tailgatingDurationSeconds++;
      if (_tailgatingDurationSeconds % 5 == 0) {
        _recalculateScore();
      }
    }

    if (_isOverspeeding) {
      _overspeedDurationSeconds++;
      if (_overspeedDurationSeconds % 10 == 0) {
        _recalculateScore();
      }
    }

    notifyListeners();
  }

  /// SOS Emergency Trigger
  void triggerSosAlert() {
    // Speaks TTS emergency notice
    _ttsService.speak(
        "Emergency SOS initiated. Sending location details to dispatch.");

    // Simulate API payload/intent
    print(
        "SOS TRIGGERED: Speed=$_currentSpeed, Lat=${_currentPositionLat()}, Long=${_currentPositionLong()}");
  }

  double _currentPositionLat() =>
      _gpsService.currentPosition?.latitude ?? 37.7749;
  double _currentPositionLong() =>
      _gpsService.currentPosition?.longitude ?? -122.4194;

  void _triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 400);
      }
    } catch (_) {}
  }

  void forceSimulatorBrake() {
    _detectorService.triggerSimulatedBrake();
  }

  void resetSimulatorMetrics() {
    _detectorService.resetSimulatorBraking();
  }
}
