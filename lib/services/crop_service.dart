//============================================================================
// CROP SERVICE - ML-based crop recommendation
//============================================================================
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/sensor_data.dart';
import 'sensor_service.dart';
//============================================================================
// CROP RECOMMENDATION MODEL
//============================================================================
class CropRecommendation {
  final String cropName;
  final double confidence;
  final String description;
  final List<String> tips;
  final String season;
  final int growthDuration; // days
  CropRecommendation({
    required this.cropName,
    required this.confidence,
    required this.description,
    required this.tips,
    required this.season,
    required this.growthDuration,
  });
  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      cropName: json['crop_name'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      season: json['season'] ?? '',
      growthDuration: json['growth_duration'] ?? 0,
    );
  }
}
//============================================================================
// CROP SERVICE CLASS
//============================================================================
class CropService extends ChangeNotifier {
// Your Python backend URL (change this to your actual backend URL)
  static const String _backendUrl = 'http://192.168.121.150:5000'; // Change this!
// Current recommendations
  List<CropRecommendation> _recommendations = [];
// Loading state
  bool _isLoading = false;
// Error message
  String? _errorMessage;
// Getters
  List<CropRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  //============================================================================
  // GET CROP RECOMMENDATIONS FROM ML MODEL
  //============================================================================

  Future<void> getCropRecommendations(SensorData sensorData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Prepare data for ML model
      final requestData = {
        'temperature': sensorData.temperature,
        'humidity': sensorData.humidity,
        'soil_moisture': sensorData.soilMoisture,
        'pH': sensorData.pH,
        'nitrogen': sensorData.nitrogen,
        'phosphorus': sensorData.phosphorus,
        'potassium': sensorData.potassium,
      };

      // Send request to Python backend
      final response = await http.post(
        Uri.parse('$_backendUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse recommendations
        _recommendations = (data['top_3_crops'] as List)
            .map((item) => CropRecommendation.fromJson(item))
            .toList();

        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to get recommendations. Status: ${response.statusCode}';
        _recommendations = [];
      }
    } catch (e) {
      debugPrint('Error getting crop recommendations: $e');
      _errorMessage = 'Could not connect to backend. Using mock data.';

      // Use mock recommendations if backend is not available
      _loadMockRecommendations(sensorData);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //===========================================================================
  // MOCK RECOMMENDATIONS (For testing without backend)
  //============================================================================

  void _loadMockRecommendations(SensorData sensorData) {
    // Generate mock recommendations based on sensor data
    _recommendations = [
      CropRecommendation(
        cropName: 'Tomato',
        confidence: 0.92,
        description: 'Tomatoes thrive in warm temperatures (20-30°C) with moderate humidity.Your current conditions are ideal for growing tomatoes.',
        tips: [
        'Plant in well-drained soil with pH 6.0-6.8',
        'Provide support stakes for growth',
        'Water regularly but avoid overwatering',
        'Add compost for better yield',
        'Monitor for common pests like aphids',
        ],
      season: 'Spring/Summer',
      growthDuration: 60,
      ),
      CropRecommendation(
        cropName: 'Lettuce',
        confidence: 0.87,
        description: 'Lettuce grows well in cooler temperatures with high humidity. Yourgreenhouse conditions support healthy lettuce growth.',
      tips: [
        'Keep soil consistently moist',
        'Harvest outer leaves first',
        'Provide partial shade in hot weather',
        'Plant every 2 weeks for continuous harvest',
        'Prefer pH range of 6.0-7.0',
        ],
      season: 'Year-round (Cool preference)',
      growthDuration: 45,
      ),
      CropRecommendation(
        cropName: 'Spinach',
        confidence: 0.83,
        description: 'Spinach is a cool-season crop that tolerates various soil conditions.Current moisture levels are suitable.',
      tips: [
        'Plant in nitrogen-rich soil',
        'Harvest leaves when 3-4 inches long',
        'Protect from extreme heat',
        'Water regularly to prevent bolting',
        'pH range: 6.5-7.5',
        ],
      season: 'Spring/Fall',
      growthDuration: 40,
      ),
      CropRecommendation(
        cropName: 'Cucumber',
        confidence: 0.79,
        description: 'Cucumbers need warm soil and consistent moisture. Your currenttemperature and humidity levels are favorable.',
      tips: [
        'Use trellises for vertical growth',
        'Water deeply and regularly',
        'Mulch to retain moisture',
        'Pick cucumbers frequently for more production',
        'Ideal pH: 6.0-7.0',
        ],
      season: 'Summer',
      growthDuration: 55,
      ),
      CropRecommendation(
        cropName: 'Basil',
        confidence: 0.75,
        description: 'Basil loves warm weather and well-drained soil. Your greenhouse providesexcellent growing conditions.',
      tips: [
      'Pinch off flower buds to encourage leaf growth',
        'Harvest regularly to promote bushiness',
        'Ensure good air circulation',
        'Water at the base to prevent fungal issues',
        'pH range: 6.0-7.5',
        ],
      season: 'Summer',
      growthDuration: 30,
      ),
    ];
  }

  //============================================================================
  // REFRESH RECOMMENDATIONS
  //============================================================================

  Future<void> refreshRecommendations(SensorData sensorData) async {
    await getCropRecommendations(sensorData);
  }
}
