// ============================================================
// FILE: lib/services/ml_service.dart
// STATUS: ✅ MOSTLY CORRECT — one addition made
//
// CHANGE: Added getMockRecommendation() public method so that
//         recommendation_tab.dart can display something useful
//         even when the Flask backend is not running.
//         (Previously the tab just showed a hard error and nothing else.)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MLService {

  // ── Backend URL ───────────────────────────────────────────────────────────
  // When testing on computer (web):
  static const String baseUrl = 'http://localhost:5000';
  // When testing on phone, change to your computer's local IP:
  // static const String baseUrl = 'http://192.168.1.100:5000';

  // ── Health check ──────────────────────────────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend not reachable: $e');
      return false;
    }
  }

  // ── Get crop recommendation ────────────────────────────────────────────────
  // pH parameter REMOVED
  Future<Map<String, dynamic>?> getCropRecommendation({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    String season   = 'Monsoon',   // optional — set a default or pass from UI
    String soilType = 'Loamy',     // optional — set a default or pass from UI
  }) async {
    try {
      // Data sent to backend — pH removed
      final data = {
        'nitrogen':    nitrogen,
        'phosphorus':  phosphorus,
        'potassium':   potassium,
        'temperature': temperature,
        'humidity':    humidity,
        'soilMoisture': soilMoisture,
        'season':      season,
        'soilType':    soilType,
        // 'pH': pH  ← REMOVED
      };

      debugPrint('Sending data to backend: $data');

      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body:    jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('Recommendation: ${result['recommended_crop']}');
        return result;
      } else {
        debugPrint('Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting recommendation: $e');
      return null;
    }
  }

  // ── Mock recommendation (used when backend is offline) ──────────────────
  // ✅ NEW: Returns a fake-but-realistic result in the same shape as the
  //         backend response, so recommendation_tab.dart can always show
  //         something rather than just an error message.
  Map<String, dynamic> getMockRecommendation(dynamic sensorData) {
    // Pick a crop based on rough heuristics
    String crop = 'Tomato';
    if ((sensorData.temperature as double) < 18)       crop = 'Wheat';
    else if ((sensorData.humidity as double) > 75)     crop = 'Rice';
    else if ((sensorData.soilMoisture as double) < 40) crop = 'Millets';

    return {
      'recommended_crop': crop,
      'confidence': 0.82,
      'status': 'mock',
      'top_3_crops': [
        {'crop': crop,       'confidence': 0.82},
        {'crop': 'Maize',    'confidence': 0.11},
        {'crop': 'Chickpea', 'confidence': 0.07},
      ],
      'recommendations': {
        'fertilizer': 'Soil nutrients N, P, K appear balanced based on readings.',
        'irrigation': (sensorData.soilMoisture as double) < 40
            ? 'Soil is dry — increase watering frequency.'
            : 'Soil moisture is adequate.',
        'climate': (sensorData.temperature as double) > 30
            ? 'High temperature — consider ventilation or shade.'
            : 'Climate conditions are favorable.',
        'notes':  '$crop is suitable for current greenhouse conditions.',
      },
    };
  }
}