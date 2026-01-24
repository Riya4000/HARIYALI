// ============================================================================
// SENSOR DATA MODEL - Structure for sensor readings
// ============================================================================

class SensorData {
  // ============================================================================
  // PROPERTIES - All sensor values
  // ============================================================================

  final double temperature;     // Temperature in Celsius
  final double humidity;         // Humidity percentage (0-100)
  final double soilMoisture;     // Soil moisture percentage (0-100)
  final double pH;               // pH level (0-14)
  final double nitrogen;         // Nitrogen level (0-100)
  final double phosphorus;       // Phosphorus level (0-100)
  final double potassium;        // Potassium level (0-100)
  final DateTime timestamp;      // When this data was recorded

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.pH,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.timestamp,
  });

  // ============================================================================
  // FROM MAP - Convert Firebase data to SensorData object
  // ============================================================================

  // This method takes a Map (from Firebase) and creates a SensorData object
  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      // Get temperature, default to 0 if missing
      temperature: (map['temperature'] ?? 0).toDouble(),

      // Get humidity, default to 0 if missing
      humidity: (map['humidity'] ?? 0).toDouble(),

      // Get soil moisture, default to 0 if missing
      soilMoisture: (map['soilMoisture'] ?? 0).toDouble(),

      // Get pH, default to 7 (neutral) if missing
      pH: (map['pH'] ?? 7).toDouble(),

      // Get NPK values, default to 0 if missing
      nitrogen: (map['nitrogen'] ?? 0).toDouble(),
      phosphorus: (map['phosphorus'] ?? 0).toDouble(),
      potassium: (map['potassium'] ?? 0).toDouble(),

      // Convert timestamp from milliseconds to DateTime
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // ============================================================================
  // TO MAP - Convert SensorData object to Map (for sending to Firebase)
  // ============================================================================

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'pH': pH,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  // Check if temperature is in optimal range
  bool get isTemperatureOptimal {
    return temperature >= 15 && temperature <= 30;
  }

  // Check if humidity is in optimal range
  bool get isHumidityOptimal {
    return humidity >= 40 && humidity <= 70;
  }

  // Check if soil moisture is in optimal range
  bool get isSoilMoistureOptimal {
    return soilMoisture >= 40 && soilMoisture <= 80;
  }

  // Check if pH is in optimal range
  bool get isPhOptimal {
    return pH >= 6.0 && pH <= 7.5;
  }

  // Get overall health status
  String get healthStatus {
    final optimal = [
      isTemperatureOptimal,
      isHumidityOptimal,
      isSoilMoistureOptimal,
      isPhOptimal,
    ];

    final optimalCount = optimal.where((o) => o).length;

    if (optimalCount == 4) return 'Excellent';
    if (optimalCount >= 3) return 'Good';
    if (optimalCount >= 2) return 'Fair';
    return 'Needs Attention';
  }

  // ============================================================================
  // TO STRING - For debugging
  // ============================================================================

  @override
  String toString() {
    return 'SensorData(temp: $temperature°C, humidity: $humidity%, '
        'moisture: $soilMoisture%, pH: $pH, timestamp: $timestamp)';
  }
}

