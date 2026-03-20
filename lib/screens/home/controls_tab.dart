// ============================================================
// FILE: lib/screens/home/controls_tab.dart
// UPDATED: Added Auto / Manual mode toggle at the top.
//   • In AUTO mode  → pump & window toggles are disabled (greyed out)
//                    → a banner explains ESP32 is in control
//   • In MANUAL mode → pump & window toggles work as before
// All existing UI (Current Conditions, Smart Tip) kept unchanged.
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── AUTO / MANUAL MODE TOGGLE CARD ─────────────────────────
                _buildModeToggleCard(sensorService),
                const SizedBox(height: 20),

                // ── AUTO MODE BANNER (shown only in auto mode) ──────────────
                if (sensorService.isAutoMode) ...[
                  _buildAutoModeBanner(),
                  const SizedBox(height: 16),
                ],

                // ── Section title changes based on mode ─────────────────────
                Text(
                  sensorService.isAutoMode
                      ? 'Device Status (Auto-Controlled)'
                      : 'Manual Controls',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sensorService.isAutoMode
                      ? 'ESP32 is controlling devices automatically'
                      : 'Control your greenhouse devices manually',
                  style: const TextStyle(
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
                  isDisabled: sensorService.isAutoMode,
                ),
                const SizedBox(height: 16),

                // Window Control
                _buildControlCard(
                  title: 'Ventilation Window',
                  subtitle: sensorService.isWindowOpen
                      ? 'Window is OPEN'
                      : 'Window is CLOSED',
                  icon: Icons.window,
                  isOn: sensorService.isWindowOpen,
                  onToggle: () => sensorService.toggleWindow(),
                  color: Colors.orange,
                  isDisabled: sensorService.isAutoMode,
                ),
                const SizedBox(height: 24),

                // ── Current Conditions ─────────────────────────────────────
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

                  // ── Smart Device Tip ──────────────────────────────────────
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

  // ── AUTO / MANUAL MODE TOGGLE CARD ────────────────────────────────────────
  Widget _buildModeToggleCard(SensorService sensorService) {
    final isAuto = sensorService.isAutoMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAuto
              ? [const Color(0xFF1565C0), const Color(0xFF1E88E5)] // blue for auto
              : [const Color(0xFF2E7D32), const Color(0xFF4CAF50)], // green for manual
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isAuto ? Colors.blue : Colors.green).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAuto ? Icons.smart_toy_rounded : Icons.touch_app_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuto ? 'Auto Mode' : 'Manual Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAuto
                      ? 'ESP32 controls devices automatically'
                      : 'You control devices from website',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Toggle switch
          Switch(
            value: isAuto,
            onChanged: (_) => sensorService.toggleMode(),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ── AUTO MODE BANNER ──────────────────────────────────────────────────────
  Widget _buildAutoModeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Auto mode is ON. The ESP32 is making decisions based on '
                  'sensor readings. Switch to Manual to control devices yourself.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTROL CARD (updated with isDisabled param) ──────────────────────────
  Widget _buildControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOn,
    required VoidCallback onToggle,
    required Color color,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.55 : 1.0,
      child: Container(
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
                    isDisabled ? '$subtitle  (Auto)' : subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled
                          ? Colors.grey
                          : (isOn ? Colors.green : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isOn,
              // If disabled (auto mode), pass null → switch becomes read-only
              onChanged: isDisabled ? null : (_) => onToggle(),
              activeColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
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

  // ── Smart Device Tip card ──────────────────────────────────────────────────
  Widget _buildSmartTip(SensorService sensorService) {
    final data = sensorService.currentData!;
    String tip = '';
    IconData tipIcon = Icons.tips_and_updates;
    Color tipColor = Colors.teal;

    if (sensorService.isAutoMode) {
      tip = 'Auto mode is active. The ESP32 will handle pump and window automatically.';
      tipIcon = Icons.smart_toy_rounded;
      tipColor = Colors.blue;
    } else if (data.soilMoisture < 35 && !sensorService.isPumpOn) {
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
      tipColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tipColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(tipIcon, color: tipColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 13, color: tipColor.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  String _tempStatus(double v) =>
      v < 15 ? 'Low' : (v <= 30 ? 'Optimal' : (v <= 38 ? 'High' : 'Critical'));
  Color _tempStatusColor(double v) =>
      v < 15 ? Colors.blue : (v <= 30 ? Colors.green : (v <= 38 ? Colors.orange : Colors.red));

  String _humidStatus(double v) =>
      v < 30 ? 'Low' : (v <= 80 ? 'Optimal' : 'High');
  Color _humidStatusColor(double v) =>
      v < 30 ? Colors.orange : (v <= 80 ? Colors.green : Colors.red);

  String _moistureStatus(double v) =>
      v < 30 ? 'Low' : (v <= 70 ? 'Optimal' : 'High');
  Color _moistureStatusColor(double v) =>
      v < 30 ? Colors.orange : (v <= 70 ? Colors.green : Colors.red);

  String _npkStatus(double v, double low, double high) =>
      v < low ? 'Low' : (v <= high ? 'Optimal' : 'High');
  Color _npkStatusColor(double v, double low, double high) =>
      v < low ? Colors.orange : (v <= high ? Colors.green : Colors.red);
}