import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Trip> _tripBox;
  late SharedPreferences _prefs;

  static const String _tripsBoxName = 'trips_v1';
  static const String _settingsPrefix = 'settings_';

  /// Initialise Hive storage, register TypeAdapters, and load settings cache.
  Future<void> init() async {
    // Initialise Hive
    await Hive.initFlutter();

    // Register manual type adapters if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WarningAdapter());
    }

    // Open Trips Box
    _tripBox = await Hive.openBox<Trip>(_tripsBoxName);

    // Initialise SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // --- TRIP LOG OPERATIONS ---

  /// Save a completed Trip record.
  Future<void> saveTrip(Trip trip) async {
    await _tripBox.put(trip.id, trip);
  }

  /// Retrieve all logged Trips, sorted by date (newest first).
  List<Trip> getTrips() {
    final List<Trip> trips = _tripBox.values.toList();
    trips.sort((a, b) => b.date.compareTo(a.date));
    return trips;
  }

  /// Delete a single Trip by ID.
  Future<void> deleteTrip(String tripId) async {
    await _tripBox.delete(tripId);
  }

  /// Delete all logged Trips.
  Future<void> clearTripHistory() async {
    await _tripBox.clear();
  }

  // --- SETTINGS OPERATIONS (SHARED PREFERENCES WRAPPER) ---

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(_settingsPrefix + key, value);
  }

  bool getBool(String key, {bool defaultValue = true}) {
    return _prefs.getBool(_settingsPrefix + key) ?? defaultValue;
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(_settingsPrefix + key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(_settingsPrefix + key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(_settingsPrefix + key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(_settingsPrefix + key) ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(_settingsPrefix + key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(_settingsPrefix + key) ?? defaultValue;
  }
}
