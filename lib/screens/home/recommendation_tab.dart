//============================================================================
// RECOMMENDATION TAB - Get AI crop suggestions
// File: lib/tabs/recommendation_tab.dart (place as appropriate in your project)
//============================================================================
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
          // Title
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

          // Get Recommendation Button
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.psychology),
              label: Text(
                _isLoading ? 'Analyzing...' : 'Get Recommendation',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Show error if any
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
                  Icon(Icons.error_outline, color: Colors.red.withValues(alpha: 0.75)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),

          // Show recommendation if available
          if (_recommendation != null)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recommended Crop Card
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
                          const Icon(Icons.agriculture, size: 60, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text(
                            'Recommended Crop',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(((double.tryParse(_recommendation!['confidence']?.toString() ?? '') ?? (_recommendation!['confidence'] ?? 0)) as num) * 100).toStringAsFixed(0)}% Confidence',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recommendations Section
                    const Text(
                      'Recommendations',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Fertilizer',
                      content: _recommendation!['recommendations']?['fertilizer'] ?? 'No data',
                      icon: Icons.science,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Irrigation',
                      content: _recommendation!['recommendations']?['irrigation'] ?? 'No data',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'pH Management',
                      content: _recommendation!['recommendations']?['pH_adjustment'] ?? 'No data',
                      icon: Icons.analytics,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),

                    _buildRecommendationCard(
                      title: 'Additional Notes',
                      content: _recommendation!['recommendations']?['notes'] ?? 'No data',
                      icon: Icons.notes,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

          // No data message
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

  //============================================================================
  // GET RECOMMENDATION FROM BACKEND
  //============================================================================
  Future<void> _getRecommendation(dynamic data) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isHealthy = await _mlService.checkHealth();

      if (!isHealthy) {
        setState(() {
          _error = 'Backend server is not running. Please start the Python server.';
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
        pH: data.pH,
        soilMoisture: data.soilMoisture,
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

  //============================================================================
  // RECOMMENDATION CARD WIDGET
  //============================================================================
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
