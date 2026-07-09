import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  // Cached settings fields
  late bool _voiceAlertsEnabled;
  late int _speedLimit; // in km/h
  late bool _hudModeEnabled;
  late bool _darkModeEnabled;
  late bool _laneDetectionEnabled;
  late bool _distanceAlertsEnabled;
  late String _sensitivity; // 'High', 'Medium', 'Low'
  late String _units; // 'Metric', 'Imperial'

  // Getters
  bool get voiceAlertsEnabled => _voiceAlertsEnabled;
  int get speedLimit => _speedLimit;
  bool get hudModeEnabled => _hudModeEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get laneDetectionEnabled => _laneDetectionEnabled;
  bool get distanceAlertsEnabled => _distanceAlertsEnabled;
  String get sensitivity => _sensitivity;
  String get units => _units;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    _voiceAlertsEnabled = _storage.getBool('voice_alerts', defaultValue: true);
    _speedLimit = _storage.getInt('speed_limit', defaultValue: 80);
    _hudModeEnabled = _storage.getBool('hud_mode', defaultValue: false);
    _darkModeEnabled = _storage.getBool('dark_mode', defaultValue: true);
    _laneDetectionEnabled = _storage.getBool('lane_detection', defaultValue: true);
    _distanceAlertsEnabled = _storage.getBool('distance_alerts', defaultValue: true);
    _sensitivity = _storage.getString('sensitivity', defaultValue: 'Medium');
    _units = _storage.getString('units', defaultValue: 'Metric');
    
    // Sync voice state to TTS engine immediately
    TtsService().enabled = _voiceAlertsEnabled;
  }

  // Setters with persistent storage write
  
  Future<void> setVoiceAlertsEnabled(bool value) async {
    _voiceAlertsEnabled = value;
    await _storage.setBool('voice_alerts', value);
    TtsService().enabled = value;
    notifyListeners();
  }

  Future<void> setSpeedLimit(int value) async {
    _speedLimit = value;
    await _storage.setInt('speed_limit', value);
    notifyListeners();
  }

  Future<void> setHudModeEnabled(bool value) async {
    _hudModeEnabled = value;
    await _storage.setBool('hud_mode', value);
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool value) async {
    _darkModeEnabled = value;
    await _storage.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setLaneDetectionEnabled(bool value) async {
    _laneDetectionEnabled = value;
    await _storage.setBool('lane_detection', value);
    notifyListeners();
  }

  Future<void> setDistanceAlertsEnabled(bool value) async {
    _distanceAlertsEnabled = value;
    await _storage.setBool('distance_alerts', value);
    notifyListeners();
  }

  Future<void> setSensitivity(String value) async {
    _sensitivity = value;
    await _storage.setString('sensitivity', value);
    notifyListeners();
  }

  Future<void> setUnits(String value) async {
    _units = value;
    await _storage.setString('units', value);
    notifyListeners();
  }
}
