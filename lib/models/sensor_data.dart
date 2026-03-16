// ============================================================
// FILE: lib/models/sensor_data.dart
// CHANGED: pH field completely removed
// ============================================================

class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.timestamp,
  });

  // Create SensorData from Firebase map
  factory SensorData.fromMap(Map<String, dynamic> data) {
    return SensorData(
      temperature:  (data['temperature']  ?? 25.0).toDouble(),
      humidity:     (data['humidity']     ?? 65.0).toDouble(),
      soilMoisture: (data['soilMoisture'] ?? 50.0).toDouble(),
      nitrogen:     (data['nitrogen']     ?? 40.0).toDouble(),
      phosphorus:   (data['phosphorus']   ?? 35.0).toDouble(),
      potassium:    (data['potassium']    ?? 42.0).toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
          : DateTime.now(),
    );
  }

  // Convert SensorData to map (for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'temperature':  temperature,
      'humidity':     humidity,
      'soilMoisture': soilMoisture,
      'nitrogen':     nitrogen,
      'phosphorus':   phosphorus,
      'potassium':    potassium,
      'timestamp':    timestamp.millisecondsSinceEpoch,
    };
  }
}