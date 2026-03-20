// ============================================================
// FILE: lib/services/ml_service.dart
// FIX: Backend URL now uses correct format for Flutter Web.
//      Flutter Web runs on a random port (e.g. localhost:53419).
//      The backend must use CORS with origins: "*" (see app.py).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MLService {

  // ── Backend URL ───────────────────────────────────────────────────────────
  // Flutter Web: use the full URL including port 5000
  // Flutter Mobile: change to your computer's local IP e.g. http://192.168.1.5:5000
  static const String baseUrl = 'http://localhost:5000';

  // ── Health check ──────────────────────────────────────────────────────────
  // Hits /health endpoint. If that fails, falls back to / (home route).
  // Uses 8 second timeout — Flask can be slow to respond the first time.
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend not reachable: $e');
      // Try fallback to home route
      try {
        final fallback = await http
            .get(Uri.parse('$baseUrl/'))
            .timeout(const Duration(seconds: 5));
        return fallback.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  // ── Get crop recommendation ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> getCropRecommendation({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    String season = 'Monsoon',
    String soilType = 'Loamy',
  }) async {
    try {
      final data = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'soilMoisture': soilMoisture,
        'season': season,
        'soilType': soilType,
        // 'pH': pH  ← REMOVED (sensor not available)
      };

      debugPrint('Sending data to backend: $data');

      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          // ✅ FIX: Some browsers require explicit Accept header
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
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

  // ── Mock recommendation (used when backend is offline) ───────────────────
  // Returns a fake-but-realistic result in the same shape as the backend
  // response, so recommendation_tab.dart can always show something useful.
  Map<String, dynamic> getMockRecommendation(dynamic sensorData) {
    // Pick a crop based on rough heuristics
    String crop = 'Tomato';
    if ((sensorData.temperature as double) < 18) {
      crop = 'Wheat';
    } else if ((sensorData.humidity as double) > 75) {
      crop = 'Rice';
    } else if ((sensorData.soilMoisture as double) < 40) {
      crop = 'Millets';
    }

    return {
      'recommended_crop': crop,
      'confidence': 0.82,
      'status': 'success',
      'top_3_crops': [
        {'crop': crop, 'confidence': 0.82},
        {'crop': 'Maize', 'confidence': 0.11},
        {'crop': 'Chickpea', 'confidence': 0.07},
      ],
      'recommendations': {
        'fertilizer': 'Soil nutrients N, P, K are well-balanced.',
        'irrigation': (sensorData.soilMoisture as double) < 40
            ? 'Soil is dry — increase watering frequency.'
            : 'Soil moisture is adequate.',
        'climate': (sensorData.temperature as double) > 32
            ? 'High temperature — consider ventilation or shade.'
            : 'Climate conditions are favorable.',
        'notes': '$crop is suitable for current conditions.',
      },
    };
  }
}