import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  StreamController<Position>? _positionStreamController;
  StreamSubscription<Position>? _positionSubscription;

  // Cache last read position & status
  Position? _currentPosition;
  bool _isServiceEnabled = false;
  LocationPermission _permissionStatus = LocationPermission.denied;

  Position? get currentPosition => _currentPosition;
  bool get isServiceEnabled => _isServiceEnabled;
  LocationPermission get permissionStatus => _permissionStatus;

  /// Check GPS permissions and service status.
  Future<bool> checkGpsAvailability() async {
    _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isServiceEnabled) return false;

    _permissionStatus = await Geolocator.checkPermission();
    if (_permissionStatus == LocationPermission.denied) {
      _permissionStatus = await Geolocator.requestPermission();
      if (_permissionStatus == LocationPermission.denied) {
        return false;
      }
    }

    if (_permissionStatus == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start streaming GPS updates. Speed is extracted from position.
  Stream<Position> startSpeedStream() {
    _positionStreamController ??= StreamController<Position>.broadcast();

    _positionSubscription?.cancel();

    // Set standard navigation parameters for precise driving updates
    var locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: Duration(milliseconds: 500),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: "DriveAssist AI Navigation Active",
        notificationText:
            "DriveAssist AI is analyzing speed and location data.",
        notificationIcon:
            AndroidResource(name: 'notification_icon', defType: 'drawable'),
        enableWakeLock: true,
      ),
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _currentPosition = position;
        _positionStreamController?.add(position);
      },
      onError: (error) {
        print("Geolocator stream error: $error");
        _positionStreamController?.addError(error);
      },
    );

    return _positionStreamController!.stream;
  }

  /// Stop the location update stream.
  void stopSpeedStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionStreamController?.close();
    _positionStreamController = null;
  }

  /// Helper to calculate current speed from position in km/h.
  /// position.speed is in meters/second.
  double getSpeedKmh(Position position) {
    if (position.speed < 0) return 0.0; // Filter noise
    return double.parse((position.speed * 3.6).toStringAsFixed(1));
  }
}
