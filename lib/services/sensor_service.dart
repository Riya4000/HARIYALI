// ============================================================================
// SENSOR SERVICE - Manages sensor data from Firebase
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class SensorService extends ChangeNotifier {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // Firebase database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Current sensor readings
  SensorData? _currentData;
  SensorData? get currentData => _currentData;

  // Historical data for charts (last 24 hours)
  List<SensorData> _historicalData = [];
  List<SensorData> get historicalData => _historicalData;

  // Device control states
  bool _isPumpOn = false;
  bool get isPumpOn => _isPumpOn;

  bool _isWindowOpen = false;
  bool get isWindowOpen => _isWindowOpen;

  bool _isLightOn = false;
  bool get isLightOn => _isLightOn;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // User ID (from auth)
  String? _userId;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  // Initialize with user ID and start listening to data
  void initialize(String userId) {
    _userId = userId;
    _listenToSensorData();
    _listenToControlStates();
    _loadHistoricalData();
  }

  // ============================================================================
  // LISTEN TO REAL-TIME SENSOR DATA
  // ============================================================================

  void _listenToSensorData() {
    if (_userId == null) return;

    // Listen to sensor data changes in Firebase
    _database.child('sensors/$_userId/current').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _currentData = SensorData.fromMap(data);
        // ← ADD THIS: also append to history list for live chart updates
        if (_historicalData.length > 200) {
          _historicalData.removeAt(0);  // Keep max 200 points
        }
        _historicalData.add(_currentData!);
        notifyListeners(); // Tell UI to update
      }
    });
  }

  // ============================================================================
  // LISTEN TO CONTROL STATES
  // ============================================================================

  void _listenToControlStates() {
    if (_userId == null) return;

    // Listen to pump state
    _database.child('controls/$_userId/pump').onValue.listen((event) {
      _isPumpOn = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });

    // Listen to window state
    _database.child('controls/$_userId/window').onValue.listen((event) {
      _isWindowOpen = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });

    // Listen to light state
    _database.child('controls/$_userId/light').onValue.listen((event) {
      _isLightOn = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });
  }

  // ============================================================================
  // LOAD HISTORICAL DATA (for charts)
  // ============================================================================

  Future<void> _loadHistoricalData() async {
    if (_userId == null) return;

    try {
      // Get last 24 hours of data
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final snapshot = await _database
          .child('history/$_userId')
          .orderByChild('timestamp')
          .startAt(yesterday.millisecondsSinceEpoch.toDouble())
          .get();

      if (snapshot.value != null) {
        final rawMap = snapshot.value as Map;
        _historicalData = rawMap.values
            .map((data) => SensorData.fromMap(Map<String, dynamic>.from(data as Map)))
            .toList();
        _historicalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
      } else {
        // No history yet — seed with some test data so graph is visible
        _historicalData = _generateTestHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading historical data: $e');
      _historicalData = _generateTestHistory();
      notifyListeners();
    }
  }

  // Generates fake history so graph shows something while waiting for real data
  List<SensorData> _generateTestHistory() {
    final now = DateTime.now();
    return List.generate(20, (i) {
      return SensorData(
        temperature:  22.0 + (i % 5),
        humidity:     60.0 + (i % 10),
        soilMoisture: 50.0 + (i % 15),
        pH:           6.5 + (i % 3) * 0.2,
        nitrogen:     60.0,
        phosphorus:   40.0,
        potassium:    50.0,
        timestamp:    now.subtract(Duration(minutes: (20 - i) * 30)),
      );
    });
  }
  // ============================================================================
  // MANUAL REFRESH
  // ============================================================================

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    await _loadHistoricalData();

    _isLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // CONTROL DEVICES (send commands to ESP32)
  // ============================================================================

  // Turn water pump on/off
  Future<void> togglePump() async {
    if (_userId == null) return;

    try {
      await _database.child('controls/$_userId/pump').set(!_isPumpOn);
    } catch (e) {
      debugPrint('Error toggling pump: $e');
    }
  }

  // Open/close window
  Future<void> toggleWindow() async {
    if (_userId == null) return;

    try {
      await _database.child('controls/$_userId/window').set(!_isWindowOpen);
    } catch (e) {
      debugPrint('Error toggling window: $e');
    }
  }

  // Turn light on/off
  Future<void> toggleLight() async {
    if (_userId == null) return;

    try {
      await _database.child('controls/$_userId/light').set(!_isLightOn);
    } catch (e) {
      debugPrint('Error toggling light: $e');
    }
  }

  // ============================================================================
  // VOICE COMMAND PROCESSING
  // ============================================================================

  Future<String> processVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    // Water pump commands
    if (lowerCommand.contains('water') || lowerCommand.contains('pump')) {
      if (lowerCommand.contains('on') || lowerCommand.contains('start')) {
        await _database.child('controls/$_userId/pump').set(true);
        return 'Water pump turned on';
      } else if (lowerCommand.contains('off') || lowerCommand.contains('stop')) {
        await _database.child('controls/$_userId/pump').set(false);
        return 'Water pump turned off';
      }
    }

    // Window commands
    if (lowerCommand.contains('window')) {
      if (lowerCommand.contains('open')) {
        await _database.child('controls/$_userId/window').set(true);
        return 'Window opened';
      } else if (lowerCommand.contains('close')) {
        await _database.child('controls/$_userId/window').set(false);
        return 'Window closed';
      }
    }

    // Light commands
    if (lowerCommand.contains('light') || lowerCommand.contains('bulb')) {
      if (lowerCommand.contains('on')) {
        await _database.child('controls/$_userId/light').set(true);
        return 'Light turned on';
      } else if (lowerCommand.contains('off')) {
        await _database.child('controls/$_userId/light').set(false);
        return 'Light turned off';
      }
    }

    // Status check
    if (lowerCommand.contains('status') || lowerCommand.contains('how')) {
      if (_currentData != null) {
        return 'Temperature: ${_currentData!.temperature.toStringAsFixed(1)}°C, '
            'Humidity: ${_currentData!.humidity.toStringAsFixed(1)}%, '
            'Soil Moisture: ${_currentData!.soilMoisture.toStringAsFixed(1)}%';
      }
    }

    return 'Sorry, I did not understand that command';
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    // Clean up listeners when service is destroyed
    super.dispose();
  }
}
