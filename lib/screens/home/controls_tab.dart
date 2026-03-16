// ============================================================
// FILE: lib/screens/home/controls_tab.dart
// ENHANCED: Original manual controls kept exactly the same.
// "Current Conditions" section expanded with:
//   - Status badge per reading (Optimal / Low / High / Critical)
//   - NPK nutrient readings
//   - A smart "Device Suggestion" tip based on conditions
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sensor_service.dart';

class ControlsTab extends StatelessWidget {
  const ControlsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorService>(
      builder: (context, sensorService, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView( // ✅ Added scrollable wrapper
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual Controls',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Control your greenhouse devices manually',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Water Pump Control
                _buildControlCard(
                  title: 'Water Pump',
                  subtitle: sensorService.isPumpOn ? 'Pump is ON' : 'Pump is OFF',
                  icon: Icons.water,
                  isOn: sensorService.isPumpOn,
                  onToggle: () => sensorService.togglePump(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),

                // Window Control
                _buildControlCard(
                  title: 'Ventilation Window',
                  subtitle: sensorService.isWindowOpen ? 'Window is OPEN' : 'Window is CLOSED',
                  icon: Icons.window,
                  isOn: sensorService.isWindowOpen,
                  onToggle: () => sensorService.toggleWindow(),
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),

                // Light Control
                _buildControlCard(
                  title: 'Grow Light',
                  subtitle: sensorService.isLightOn ? 'Light is ON' : 'Light is OFF',
                  icon: Icons.lightbulb,
                  isOn: sensorService.isLightOn,
                  onToggle: () => sensorService.toggleLight(),
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),

                // ── Current Conditions (ENHANCED) ─────────────────────
                const Text(
                  'Current Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (sensorService.currentData != null) ...[
                  // Temperature
                  _buildConditionRowWithStatus(
                    'Temperature',
                    '${sensorService.currentData!.temperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                    Colors.red,
                    _tempStatus(sensorService.currentData!.temperature),
                    _tempStatusColor(sensorService.currentData!.temperature),
                    hint: 'Optimal: 15–30°C',
                  ),
                  const SizedBox(height: 8),

                  // Humidity
                  _buildConditionRowWithStatus(
                    'Humidity',
                    '${sensorService.currentData!.humidity.toStringAsFixed(1)}%',
                    Icons.water_drop,
                    Colors.blue,
                    _humidStatus(sensorService.currentData!.humidity),
                    _humidStatusColor(sensorService.currentData!.humidity),
                    hint: 'Optimal: 50–80%',
                  ),
                  const SizedBox(height: 8),

                  // Soil Moisture
                  _buildConditionRowWithStatus(
                    'Soil Moisture',
                    '${sensorService.currentData!.soilMoisture.toStringAsFixed(1)}%',
                    Icons.grass,
                    Colors.green,
                    _moistureStatus(sensorService.currentData!.soilMoisture),
                    _moistureStatusColor(sensorService.currentData!.soilMoisture),
                    hint: 'Optimal: 40–70%',
                  ),
                  const SizedBox(height: 8),

                  // Nitrogen
                  _buildConditionRowWithStatus(
                    'Nitrogen (N)',
                    '${sensorService.currentData!.nitrogen.toStringAsFixed(0)} mg/kg',
                    Icons.science,
                    Colors.green.shade700,
                    _npkStatus(sensorService.currentData!.nitrogen, 40, 110),
                    _npkStatusColor(sensorService.currentData!.nitrogen, 40, 110),
                    hint: 'Optimal: 40–110 mg/kg',
                  ),
                  const SizedBox(height: 8),

                  // Phosphorus
                  _buildConditionRowWithStatus(
                    'Phosphorus (P)',
                    '${sensorService.currentData!.phosphorus.toStringAsFixed(0)} mg/kg',
                    Icons.science,
                    Colors.orange,
                    _npkStatus(sensorService.currentData!.phosphorus, 30, 80),
                    _npkStatusColor(sensorService.currentData!.phosphorus, 30, 80),
                    hint: 'Optimal: 30–80 mg/kg',
                  ),
                  const SizedBox(height: 8),

                  // Potassium
                  _buildConditionRowWithStatus(
                    'Potassium (K)',
                    '${sensorService.currentData!.potassium.toStringAsFixed(0)} mg/kg',
                    Icons.science,
                    Colors.purple,
                    _npkStatus(sensorService.currentData!.potassium, 30, 80),
                    _npkStatusColor(sensorService.currentData!.potassium, 30, 80),
                    hint: 'Optimal: 30–80 mg/kg',
                  ),
                  const SizedBox(height: 16),

                  // ── Smart Device Tip ──────────────────────────────────
                  _buildSmartTip(sensorService),

                ] else
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Original _buildControlCard (unchanged) ────────────────────────────────
  Widget _buildControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOn,
    required VoidCallback onToggle,
    required Color color,
  }) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isOn ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: (value) => onToggle(),
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  // ── Enhanced condition row with status badge ───────────────────────────────
  Widget _buildConditionRowWithStatus(
      String label,
      String value,
      IconData icon,
      Color iconColor,
      String status,
      Color statusColor, {
        String? hint,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'Optimal' ? Icons.check_circle : Icons.warning_amber,
                      size: 11,
                      color: statusColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  hint,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Smart Device Tip card ─────────────────────────────────────────────────
  Widget _buildSmartTip(SensorService sensorService) {
    final data = sensorService.currentData!;
    String tip = '';
    IconData tipIcon = Icons.tips_and_updates;
    Color tipColor = Colors.teal;

    if (data.soilMoisture < 35 && !sensorService.isPumpOn) {
      tip = 'Soil moisture is low. Consider turning on the Water Pump.';
      tipIcon = Icons.water;
      tipColor = Colors.blue;
    } else if (data.temperature > 32 && !sensorService.isWindowOpen) {
      tip = 'Temperature is high. Opening the Ventilation Window may help.';
      tipIcon = Icons.window;
      tipColor = Colors.orange;
    } else if (data.humidity < 45 && !sensorService.isPumpOn) {
      tip = 'Humidity is low. Running the Water Pump can help raise it.';
      tipIcon = Icons.water_drop;
      tipColor = Colors.blue;
    } else if (sensorService.isPumpOn && data.soilMoisture > 72) {
      tip = 'Soil moisture is high — you can turn off the Water Pump.';
      tipIcon = Icons.water_drop;
      tipColor = Colors.red;
    } else {
      tip = 'All conditions look good. No device changes needed right now.';
      tipIcon = Icons.check_circle_outline;
      tipColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tipColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tipIcon, color: tipColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Suggestion',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tipColor),
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: TextStyle(fontSize: 13, color: tipColor.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _tempStatus(double t) {
    if (t < 15) return 'Low';
    if (t > 30) return 'High';
    return 'Optimal';
  }
  Color _tempStatusColor(double t) {
    if (t < 15) return Colors.blue;
    if (t > 30) return Colors.red;
    return Colors.green;
  }

  String _humidStatus(double h) {
    if (h < 50) return 'Low';
    if (h > 80) return 'High';
    return 'Optimal';
  }
  Color _humidStatusColor(double h) {
    if (h < 50) return Colors.orange;
    if (h > 80) return Colors.blue;
    return Colors.green;
  }

  String _moistureStatus(double m) {
    if (m < 30) return 'Critical';
    if (m < 40) return 'Low';
    if (m > 70) return 'High';
    return 'Optimal';
  }
  Color _moistureStatusColor(double m) {
    if (m < 30) return Colors.red;
    if (m < 40) return Colors.orange;
    if (m > 70) return Colors.blue;
    return Colors.green;
  }

  String _npkStatus(double v, double low, double high) {
    if (v < low) return 'Low';
    if (v > high) return 'High';
    return 'Optimal';
  }
  Color _npkStatusColor(double v, double low, double high) {
    if (v < low) return Colors.orange;
    if (v > high) return Colors.red;
    return Colors.green;
  }
}