// ============================================================
// FILE: lib/services/sensor_service.dart
// UPDATED: Added isAutoMode, toggleMode(), setMode() support.
//          In auto mode, togglePump() and toggleWindow() are blocked
//          on the Flutter side. The ESP32 reads the "mode" field from
//          Firebase and ignores website control commands when in auto.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class SensorService extends ChangeNotifier {

  // ── Properties ────────────────────────────────────────────────────────────
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  SensorData? _currentData;
  SensorData? get currentData => _currentData;

  List<SensorData> _historicalData = [];
  List<SensorData> get historicalData => _historicalData;

  bool _isPumpOn = false;
  bool get isPumpOn => _isPumpOn;

  bool _isWindowOpen = false;
  bool get isWindowOpen => _isWindowOpen;

  // ── NEW: Auto/Manual mode ─────────────────────────────────────────────────
  // true = auto mode (ESP32 controls devices autonomously)
  // false = manual mode (website/voice controls devices)
  bool _isAutoMode = false;
  bool get isAutoMode => _isAutoMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userId;

  // ── Initialization ────────────────────────────────────────────────────────
  void initialize(String userId) {
    _userId = userId;
    _listenToSensorData();
    _listenToControlStates();
    _listenToMode();           // NEW: listen to mode changes
    _loadHistoricalData();
  }

  // ── Listen to real-time sensor data ───────────────────────────────────────
  void _listenToSensorData() {
    if (_userId == null) return;

    _database.child('sensors/$_userId/current').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _currentData = SensorData.fromMap(data);

        // Append to history for live chart updates (keep max 200 points)
        if (_historicalData.length > 200) {
          _historicalData.removeAt(0);
        }
        _historicalData.add(_currentData!);
        notifyListeners();
      }
    });
  }

  // ── Listen to control states ───────────────────────────────────────────────
  void _listenToControlStates() {
    if (_userId == null) return;

    _database.child('controls/$_userId/pump').onValue.listen((event) {
      _isPumpOn = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });

    _database.child('controls/$_userId/window').onValue.listen((event) {
      _isWindowOpen = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });
  }

  // ── NEW: Listen to mode field ─────────────────────────────────────────────
  // Firebase path: controls/<userId>/mode  →  "auto" | "manual"
  void _listenToMode() {
    if (_userId == null) return;

    _database.child('controls/$_userId/mode').onValue.listen((event) {
      final value = event.snapshot.value as String? ?? 'manual';
      _isAutoMode = (value == 'auto');
      notifyListeners();
    });
  }

  // ── NEW: Toggle between auto and manual mode ──────────────────────────────
  Future<void> toggleMode() async {
    if (_userId == null) return;
    final newMode = _isAutoMode ? 'manual' : 'auto';
    try {
      await _database.child('controls/$_userId/mode').set(newMode);
    } catch (e) {
      debugPrint('Error toggling mode: $e');
    }
  }

  // ── NEW: Set mode explicitly ──────────────────────────────────────────────
  Future<void> setMode(bool autoMode) async {
    if (_userId == null) return;
    try {
      await _database
          .child('controls/$_userId/mode')
          .set(autoMode ? 'auto' : 'manual');
    } catch (e) {
      debugPrint('Error setting mode: $e');
    }
  }

  // ── Load historical data ──────────────────────────────────────────────────
  Future<void> _loadHistoricalData() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final snapshot = await _database
          .child('history/$_userId')
          .orderByChild('timestamp')
          .startAt(yesterday.millisecondsSinceEpoch.toDouble())
          .get();

      if (snapshot.value != null) {
        final rawMap = snapshot.value as Map;

        List<SensorData> loaded = [];
        for (final entry in rawMap.values) {
          try {
            final map = Map<String, dynamic>.from(entry as Map);

            Map<String, dynamic> sensorFields;
            if (map.containsKey('sensor_data') && map['sensor_data'] is Map) {
              sensorFields = Map<String, dynamic>.from(map['sensor_data'] as Map);
              if (!sensorFields.containsKey('timestamp') &&
                  map.containsKey('timestamp')) {
                sensorFields['timestamp'] = map['timestamp'];
              }
            } else {
              sensorFields = map;
            }

            loaded.add(SensorData.fromMap(sensorFields));
          } catch (e) {
            debugPrint('Skipping malformed history entry: $e');
          }
        }

        if (loaded.isNotEmpty) {
          _historicalData = loaded
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        } else {
          _historicalData = _generateTestHistory();
        }
        notifyListeners();
      } else {
        _historicalData = _generateTestHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading historical data: $e');
      _historicalData = _generateTestHistory();
      notifyListeners();
    }
  }

  // ── Test history (used when Firebase has no history) ──────────────────────
  List<SensorData> _generateTestHistory() {
    final now = DateTime.now();
    return List.generate(20, (i) {
      return SensorData(
        temperature: 22.0 + (i % 5),
        humidity: 60.0 + (i % 10),
        soilMoisture: 50.0 + (i % 15),
        nitrogen: 60.0,
        phosphorus: 40.0,
        potassium: 50.0,
        timestamp: now.subtract(Duration(minutes: (20 - i) * 30)),
      );
    });
  }

  // ── Manual refresh ────────────────────────────────────────────────────────
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await _loadHistoricalData();
    _isLoading = false;
    notifyListeners();
  }

  // ── Device controls ───────────────────────────────────────────────────────
  // UPDATED: All toggle/set methods check mode before writing to Firebase.
  // In auto mode, the website CANNOT change pump or window state.

  // Toggle pump — blocked in auto mode
  Future<void> togglePump() async {
    if (_userId == null) return;
    if (_isAutoMode) {
      debugPrint('Auto mode active: pump control blocked from website.');
      return;
    }
    try {
      await _database.child('controls/$_userId/pump').set(!_isPumpOn);
    } catch (e) {
      debugPrint('Error toggling pump: $e');
    }
  }

  // Set pump to exact state — blocked in auto mode (used by voice tab)
  Future<void> setPump(bool state) async {
    if (_userId == null) return;
    if (_isAutoMode) {
      debugPrint('Auto mode active: pump control blocked from website.');
      return;
    }
    try {
      await _database.child('controls/$_userId/pump').set(state);
    } catch (e) {
      debugPrint('Error setting pump: $e');
    }
  }

  // Toggle window — blocked in auto mode
  Future<void> toggleWindow() async {
    if (_userId == null) return;
    if (_isAutoMode) {
      debugPrint('Auto mode active: window control blocked from website.');
      return;
    }
    try {
      await _database.child('controls/$_userId/window').set(!_isWindowOpen);
    } catch (e) {
      debugPrint('Error toggling window: $e');
    }
  }

  // Set window to exact state — blocked in auto mode (used by voice tab)
  Future<void> setWindow(bool state) async {
    if (_userId == null) return;
    if (_isAutoMode) {
      debugPrint('Auto mode active: window control blocked from website.');
      return;
    }
    try {
      await _database.child('controls/$_userId/window').set(state);
    } catch (e) {
      debugPrint('Error setting window: $e');
    }
  }
}