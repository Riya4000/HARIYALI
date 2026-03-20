// ============================================================
// FILE: lib/screens/home/dashboard_tab.dart
// CHANGED: pH stat card removed, _getPhColor() removed
// CHANGED: Grow Light status removed from System Status (no physical LED)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/sensor_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorService>(
      builder: (context, sensorService, child) {
        final data = sensorService.currentData;

        if (data == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => sensorService.refreshData(),
          color: const Color(0xFF4CAF50),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Welcome card ────────────────────────────────────────
                _buildWelcomeCard(context),
                const SizedBox(height: 16),

                // ── System Status ────────────────────────────────────────
                _buildStatusOverview(sensorService),
                const SizedBox(height: 16),

                // ── Quick Stats title ────────────────────────────────────
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Row 1: Temperature + Humidity
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        'Temperature',
                        '${data.temperature.toStringAsFixed(1)}°C',
                        Icons.thermostat,
                        _getTemperatureColor(data.temperature),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickStatCard(
                        'Humidity',
                        '${data.humidity.toStringAsFixed(1)}%',
                        Icons.water_drop,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Soil Moisture — pH card REMOVED
                _buildQuickStatCard(
                  'Soil Moisture',
                  '${data.soilMoisture.toStringAsFixed(1)}%',
                  Icons.grass,
                  _getSoilMoistureColor(data.soilMoisture),
                ),
                const SizedBox(height: 16),

                // ── Soil Nutrients ────────────────────────────────────────
                const Text(
                  'Soil Nutrients',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildNutrientCard('Nitrogen (N)', data.nitrogen, Colors.green),
                const SizedBox(height: 8),
                _buildNutrientCard('Phosphorus (P)', data.phosphorus, Colors.orange),
                const SizedBox(height: 8),
                _buildNutrientCard('Potassium (K)', data.potassium, Colors.purple),
                const SizedBox(height: 16),

                // ── Last updated ─────────────────────────────────────────
                Center(
                  child: Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy - hh:mma').format(data.timestamp)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Welcome card ──────────────────────────────────────────────────────────
  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
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
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'HARIYALI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Smart Greenhouse System',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome! Your greenhouse is being monitored in real-time.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── System status — Light item REMOVED ────────────────────────────────────
  Widget _buildStatusOverview(SensorService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Only two items now: Water Pump + Window (Light removed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem('Water Pump', service.isPumpOn, Icons.water),
              _buildStatusItem('Window', service.isWindowOpen, Icons.window),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isOn, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOn
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isOn ? Colors.green : Colors.grey, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          isOn ? 'ON' : 'OFF',
          style: TextStyle(
            fontSize: 11,
            color: isOn ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Quick stat card ───────────────────────────────────────────────────────
  Widget _buildQuickStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Nutrient card ─────────────────────────────────────────────────────────
  Widget _buildNutrientCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label.split('(')[1].replaceAll(')', ''),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Color helpers — _getPhColor() REMOVED ─────────────────────────────────
  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp > 30) return Colors.red;
    return Colors.green;
  }

  Color _getSoilMoistureColor(double moisture) {
    if (moisture < 30) return Colors.orange;
    if (moisture > 70) return Colors.blue;
    return Colors.green;
  }
}