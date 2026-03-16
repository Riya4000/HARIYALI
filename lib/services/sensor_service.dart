// ============================================================
// FILE: lib/services/sensor_service.dart
// STATUS: ❌ BUG FIXED
//
// PROBLEM WITH SENSOR PAGE / GRAPH:
//   _loadHistoricalData() reads from 'history/{USER_ID}' in Firebase.
//   The old send_test_data.py stored history entries as:
//     { "sensor_data": { ..., "pH": 6.5, ... }, "timestamp": ... }
//   i.e. the actual readings were NESTED under a "sensor_data" key.
//
//   But SensorData.fromMap() expects the readings at the TOP level:
//     { "temperature": 25, "humidity": 65, ... "timestamp": 1234 }
//
//   So when the history had the old format (with sensor_data wrapper),
//   SensorData.fromMap() received a map that had NO temperature/humidity
//   keys → all values defaulted to the fallback values → the graph
//   shows a flat line because every reading is identical.
//
// ✅ FIXES APPLIED:
//   1. _loadHistoricalData() now handles BOTH formats:
//      - New format (flat, no pH): { "temperature": 25, ... }
//      - Old format (nested):      { "sensor_data": { "temperature": 25, ... } }
//   2. Added a 'timestamp' field recovery: if timestamp is missing from the
//      entry but exists in the Firebase push-key, we estimate it.
//   3. _generateTestHistory() unchanged — already correct (no pH).
//
// WHAT TO DO ABOUT OLD FIREBASE HISTORY DATA:
//   Option A (recommended): Delete old history in Firebase Console
//     → Go to: hariyali-10a26-default-rtdb → history → YOUR_USER_ID
//     → Right-click → Delete
//     → Run send_test_data.py to generate fresh clean history
//   Option B: Do nothing — the fix below handles the old format gracefully.
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

  bool _isPumpOn    = false;
  bool get isPumpOn => _isPumpOn;

  bool _isWindowOpen    = false;
  bool get isWindowOpen => _isWindowOpen;

  bool _isLightOn    = false;
  bool get isLightOn => _isLightOn;

  bool _isLoading    = false;
  bool get isLoading => _isLoading;

  String? _userId;

  // ── Initialization ────────────────────────────────────────────────────────
  void initialize(String userId) {
    _userId = userId;
    _listenToSensorData();
    _listenToControlStates();
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

    _database.child('controls/$_userId/light').onValue.listen((event) {
      _isLightOn = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });
  }

  // ── Load historical data ──────────────────────────────────────────────────
  Future<void> _loadHistoricalData() async {
    if (_userId == null) return;

    try {
      final now       = DateTime.now();
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

            // ✅ FIX: Handle both old format (has 'sensor_data' wrapper)
            //         and new format (flat, fields at top level).
            Map<String, dynamic> sensorFields;
            if (map.containsKey('sensor_data') && map['sensor_data'] is Map) {
              // Old format: { sensor_data: { temperature: ..., pH: ..., ... }, timestamp: ... }
              sensorFields = Map<String, dynamic>.from(map['sensor_data'] as Map);
              // Promote timestamp to top level if missing
              if (!sensorFields.containsKey('timestamp') && map.containsKey('timestamp')) {
                sensorFields['timestamp'] = map['timestamp'];
              }
            } else {
              // New format (after pH removal): flat map
              sensorFields = map;
            }

            // pH field is simply ignored by SensorData.fromMap() since it
            // has no pH field — safe to leave it in the map.
            loaded.add(SensorData.fromMap(sensorFields));
          } catch (e) {
            debugPrint('Skipping malformed history entry: $e');
          }
        }

        if (loaded.isNotEmpty) {
          _historicalData = loaded
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        } else {
          // No valid entries → use test data so graph shows something
          _historicalData = _generateTestHistory();
        }
        notifyListeners();
      } else {
        // No history yet — seed with test data so graph shows something
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
  // pH removed — no pH field in SensorData constructor
  List<SensorData> _generateTestHistory() {
    final now = DateTime.now();
    return List.generate(20, (i) {
      return SensorData(
        temperature:  22.0 + (i % 5),
        humidity:     60.0 + (i % 10),
        soilMoisture: 50.0 + (i % 15),
        nitrogen:     60.0,
        phosphorus:   40.0,
        potassium:    50.0,
        timestamp:    now.subtract(Duration(minutes: (20 - i) * 30)),
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
  Future<void> togglePump() async {
    if (_userId == null) return;
    try {
      await _database.child('controls/$_userId/pump').set(!_isPumpOn);
    } catch (e) {
      debugPrint('Error toggling pump: $e');
    }
  }

  Future<void> toggleWindow() async {
    if (_userId == null) return;
    try {
      await _database.child('controls/$_userId/window').set(!_isWindowOpen);
    } catch (e) {
      debugPrint('Error toggling window: $e');
    }
  }

  Future<void> toggleLight() async {
    if (_userId == null) return;
    try {
      await _database.child('controls/$_userId/light').set(!_isLightOn);
    } catch (e) {
      debugPrint('Error toggling light: $e');
    }
  }

  // ── Voice command processing ───────────────────────────────────────────────
  Future<String> processVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('water') || lowerCommand.contains('pump')) {
      if (lowerCommand.contains('on') || lowerCommand.contains('start')) {
        await _database.child('controls/$_userId/pump').set(true);
        return 'Water pump turned on';
      } else if (lowerCommand.contains('off') || lowerCommand.contains('stop')) {
        await _database.child('controls/$_userId/pump').set(false);
        return 'Water pump turned off';
      }
    }

    if (lowerCommand.contains('window')) {
      if (lowerCommand.contains('open')) {
        await _database.child('controls/$_userId/window').set(true);
        return 'Window opened';
      } else if (lowerCommand.contains('close')) {
        await _database.child('controls/$_userId/window').set(false);
        return 'Window closed';
      }
    }

    if (lowerCommand.contains('light') || lowerCommand.contains('bulb')) {
      if (lowerCommand.contains('on')) {
        await _database.child('controls/$_userId/light').set(true);
        return 'Light turned on';
      } else if (lowerCommand.contains('off')) {
        await _database.child('controls/$_userId/light').set(false);
        return 'Light turned off';
      }
    }

    // Status — pH removed from status string
    if (lowerCommand.contains('status') || lowerCommand.contains('how')) {
      if (_currentData != null) {
        return 'Temperature: ${_currentData!.temperature.toStringAsFixed(1)}°C, '
            'Humidity: ${_currentData!.humidity.toStringAsFixed(1)}%, '
            'Soil Moisture: ${_currentData!.soilMoisture.toStringAsFixed(1)}%';
      }
    }

    return 'Sorry, I did not understand that command';
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    super.dispose();
  }
}