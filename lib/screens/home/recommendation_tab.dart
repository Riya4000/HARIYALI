// ============================================================
// FILE: lib/screens/home/recommendation_tab.dart
// STATUS: ❌ BUG FIXED
//
// ROOT CAUSE OF "not loading" error:
// The backend returns:
// { "recommendations": { "fertilizer": "...", "irrigation": "...",
//                         "climate": "...", "notes": "..." } }
// But the UI was reading:
// _recommendation!['recommendations']?['fertilizer']   ← correct ✅
// _recommendation!['recommendations']?['climate']       ← correct ✅
//
// However the REAL problem was in ml_service.dart:
// getCropRecommendation() returns the full result dict from backend,
// but it was only used IF checkHealth() passes.
// If Flask is not running (very common), health check fails → shows
// "Backend server is not running" instead of showing any results.
//
// FIXES IN THIS FILE:
//   1. When backend is unreachable, show mock data (not just an error)
//   2. Added null-safety for recommendations sub-keys
//   3. Fixed confidence display (backend returns float 0..1, need *100)
//   4. Removed the "season" and "duration" display cards that assumed
//      recommendations contained those keys (they are in the nested
//      recommendations dict from crop_predictor, not at top level)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sensor_service.dart';
import '../../services/ml_service.dart';

class RecommendationTab extends StatefulWidget {
  const RecommendationTab({super.key});

  @override
  State<RecommendationTab> createState() => _RecommendationTabState();
}

class _RecommendationTabState extends State<RecommendationTab> {
  final MLService _mlService = MLService();

  bool _isLoading = false;
  Map<String, dynamic>? _recommendation;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final sensorService = Provider.of<SensorService>(context);
    final data = sensorService.currentData;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Title ─────────────────────────────────────────────────────
          const Text(
            'Crop Recommendation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get AI-powered crop suggestions based on your soil conditions',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // ── Get Recommendation Button ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: data == null || _isLoading
                  ? null
                  : () => _getRecommendation(data),
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.psychology),
              label: Text(
                _isLoading ? 'Analyzing...' : 'Get Recommendation',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Error banner ───────────────────────────────────────────────
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.withValues(alpha: 0.75)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.85))),
                  ),
                ],
              ),
            ),

          // ── Recommendation results ─────────────────────────────────────
          if (_recommendation != null)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Hero card: recommended crop ───────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.agriculture,
                              size: 60, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text('Recommended Crop',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            (_recommendation!['recommended_crop'] ?? 'Unknown')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              // ✅ FIX: confidence from backend is 0.0–1.0 float
                              '${(((((_recommendation!['confidence'] ?? 0) as num).toDouble()) * 100).toStringAsFixed(0))}% Confidence',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Top 3 crops ─────────────────────────────────────
                    const Text('Top 3 Crops',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_recommendation!['top_3_crops'] != null)
                      ...(_recommendation!['top_3_crops'] as List)
                          .asMap()
                          .entries
                          .map((entry) {
                        final int index = entry.key;
                        final item = entry.value as Map;
                        final String cropName =
                        (item['crop'] ?? 'Unknown').toString();
                        final double confidence =
                        ((item['confidence'] ?? 0) as num).toDouble();
                        final int percent = (confidence * 100).round();

                        final List<Color> medalColors = [
                          const Color(0xFFFFD700),
                          const Color(0xFFC0C0C0),
                          const Color(0xFFCD7F32),
                        ];
                        final List<String> medals = ['🥇', '🥈', '🥉'];
                        final Color color = index < medalColors.length
                            ? medalColors[index]
                            : Colors.grey;
                        final Color textColor = index == 0
                            ? Colors.orange.shade800
                            : color;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withOpacity(0.4), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                index < medals.length
                                    ? medals[index]
                                    : '${index + 1}.',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cropName[0].toUpperCase() +
                                          cropName.substring(1),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: confidence,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            color),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$percent%',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 24),

                    // ── Recommendation Criteria ──────────────────────────
                    const Text('Recommendation Criteria',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Fertilizer',
                      // ✅ FIX: backend returns recommendations as a MAP (dict), not a list
                      content:
                      (_recommendation!['recommendations']
                      as Map<String, dynamic>?)?['fertilizer']
                          ?.toString() ??
                          'No data',
                      icon: Icons.science,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Irrigation',
                      content:
                      (_recommendation!['recommendations']
                      as Map<String, dynamic>?)?['irrigation']
                          ?.toString() ??
                          'No data',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Climate',
                      content:
                      (_recommendation!['recommendations']
                      as Map<String, dynamic>?)?['climate']
                          ?.toString() ??
                          'No data',
                      icon: Icons.thermostat,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Additional Notes',
                      content:
                      (_recommendation!['recommendations']
                      as Map<String, dynamic>?)?['notes']
                          ?.toString() ??
                          'No data',
                      icon: Icons.notes,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

          // ── Waiting message when no data yet ──────────────────────────
          if (data == null && _recommendation == null && _error == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Waiting for sensor data...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Get recommendation
  // ✅ FIX: If backend is not running, we no longer show a hard error ---
  // instead we call _loadMockRecommendation() so the UI still shows
  // something useful. The error message is kept but less alarming.
  Future<void> _getRecommendation(dynamic data) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isHealthy = await _mlService.checkHealth();

      if (!isHealthy) {
        // ✅ FIX: Show mock data with a soft warning instead of hard error
        setState(() {
          _recommendation = _mlService.getMockRecommendation(data);
          _error =
          '⚠️ Backend offline — showing demo data. Start Python server for real predictions.';
          _isLoading = false;
        });
        return;
      }

      final result = await _mlService.getCropRecommendation(
        nitrogen: data.nitrogen,
        phosphorus: data.phosphorus,
        potassium: data.potassium,
        temperature: data.temperature,
        humidity: data.humidity,
        soilMoisture: data.soilMoisture,
        // pH removed
      );

      if (result != null) {
        setState(() {
          _recommendation = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to get recommendation. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // ── Recommendation card widget
  Widget _buildRecommendationCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(content,
                    style:
                    const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}