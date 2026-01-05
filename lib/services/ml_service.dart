// ============================================================================
// ML SERVICE - Connects Flutter app to Python backend
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MLService {
  // ============================================================================
  // BACKEND URL - Change this based on where you're running
  // ============================================================================

  // When testing on computer (web):
  static const String baseUrl = 'http://localhost:5000';

  // When testing on phone (change to your computer's IP):
  // Find your IP: Windows → cmd → ipconfig
  //               Mac → System Preferences → Network
  // static const String baseUrl = 'http://192.168.1.100:5000';

  // ============================================================================
  // CHECK IF BACKEND IS RUNNING
  // ============================================================================

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend not reachable: $e');
      return false;
    }
  }

  // ============================================================================
  // GET CROP RECOMMENDATION
  // ============================================================================

  Future<Map<String, dynamic>?> getCropRecommendation({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double pH,
    required double soilMoisture,
  }) async {
    try {
      // Prepare data to send
      final data = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'pH': pH,
        'soilMoisture': soilMoisture,
      };

      debugPrint('Sending data to backend: $data');

      // Send POST request to Python backend
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Backend response: ${response.statusCode}');

      // Check if request was successful
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
}