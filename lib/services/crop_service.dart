// ============================================================
// FILE: lib/services/crop_service.dart
// CHANGED: 'pH': sensorData.pH removed from requestData map
//          pH tip strings removed from mock recommendations
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/sensor_data.dart';
import 'sensor_service.dart';

// ── Crop recommendation model ──────────────────────────────────────────────────
class CropRecommendation {
  final String cropName;
  final double confidence;
  final String description;
  final List<String> tips;
  final String season;
  final int growthDuration;

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
      cropName:       json['crop_name']       ?? 'Unknown',
      confidence:     (json['confidence']     ?? 0.0).toDouble(),
      description:    json['description']     ?? '',
      tips:           List<String>.from(json['tips'] ?? []),
      season:         json['season']          ?? '',
      growthDuration: json['growth_duration'] ?? 0,
    );
  }
}

// ── Crop service ───────────────────────────────────────────────────────────────
class CropService extends ChangeNotifier {
  static const String _backendUrl = 'https://hariyali-backend.onrender.com'; // Change this!

  List<CropRecommendation> _recommendations = [];
  bool    _isLoading    = false;
  String? _errorMessage;

  List<CropRecommendation> get recommendations => _recommendations;
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Get recommendations from ML backend — pH REMOVED ──────────────────────────
  Future<void> getCropRecommendations(SensorData sensorData) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 'pH': sensorData.pH  ← LINE REMOVED
      final requestData = {
        'temperature':  sensorData.temperature,
        'humidity':     sensorData.humidity,
        'soilMoisture': sensorData.soilMoisture,
        'nitrogen':     sensorData.nitrogen,
        'phosphorus':   sensorData.phosphorus,
        'potassium':    sensorData.potassium,
        'season':       'Monsoon', // default; update if you have a UI selector
        'soilType':     'Loamy',   // default; update if you have a UI selector
      };

      final response = await http
          .post(
        Uri.parse('$_backendUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _recommendations = (data['top_3_crops'] as List)
            .map((item) => CropRecommendation.fromJson(item))
            .toList();
        _errorMessage = null;
      } else {
        _errorMessage =
        'Failed to get recommendations. Status: ${response.statusCode}';
        _recommendations = [];
      }
    } catch (e) {
      debugPrint('Error getting crop recommendations: $e');
      _errorMessage = 'Could not connect to backend. Using mock data.';
      _loadMockRecommendations(sensorData);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mock recommendations — pH tip strings REMOVED ─────────────────────────────
  void _loadMockRecommendations(SensorData sensorData) {
    _recommendations = [
      CropRecommendation(
        cropName:    'Tomato',
        confidence:  0.92,
        description: 'Tomatoes thrive in warm temperatures (20-30°C) with moderate humidity. Your current conditions are ideal for growing tomatoes.',
        tips: [
          'Provide support stakes for growth',
          'Water regularly but avoid overwatering',
          'Add compost for better yield',
          'Monitor for common pests like aphids',
        ],
        season:         'Spring/Summer',
        growthDuration: 60,
      ),
      CropRecommendation(
        cropName:    'Lettuce',
        confidence:  0.87,
        description: 'Lettuce grows well in cooler temperatures with high humidity. Your greenhouse conditions support healthy lettuce growth.',
        tips: [
          'Keep soil consistently moist',
          'Harvest outer leaves first',
          'Provide partial shade in hot weather',
          'Plant every 2 weeks for continuous harvest',
        ],
        season:         'Year-round (Cool preference)',
        growthDuration: 45,
      ),
      CropRecommendation(
        cropName:    'Spinach',
        confidence:  0.83,
        description: 'Spinach is a cool-season crop that tolerates various soil conditions. Current moisture levels are suitable.',
        tips: [
          'Plant in nitrogen-rich soil',
          'Harvest leaves when 3-4 inches long',
          'Protect from extreme heat',
          'Water regularly to prevent bolting',
        ],
        season:         'Spring/Fall',
        growthDuration: 40,
      ),
      CropRecommendation(
        cropName:    'Cucumber',
        confidence:  0.79,
        description: 'Cucumbers need warm soil and consistent moisture. Your current temperature and humidity levels are favorable.',
        tips: [
          'Use trellises for vertical growth',
          'Water deeply and regularly',
          'Mulch to retain moisture',
          'Pick cucumbers frequently for more production',
        ],
        season:         'Summer',
        growthDuration: 55,
      ),
      CropRecommendation(
        cropName:    'Basil',
        confidence:  0.75,
        description: 'Basil loves warm weather and well-drained soil. Your greenhouse provides excellent growing conditions.',
        tips: [
          'Pinch off flower buds to encourage leaf growth',
          'Harvest regularly to promote bushiness',
          'Ensure good air circulation',
          'Water at the base to prevent fungal issues',
        ],
        season:         'Summer',
        growthDuration: 30,
      ),
    ];
  }

  // ── Refresh ────────────────────────────────────────────────────────────────────
  Future<void> refreshRecommendations(SensorData sensorData) async {
    await getCropRecommendations(sensorData);
  }
}