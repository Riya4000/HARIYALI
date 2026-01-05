// ============================================================================
// CONTROLS TAB - Manual control of greenhouse devices
// ============================================================================

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

              // Current sensor readings
              const Text(
                'Current Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (sensorService.currentData != null) ...[
                _buildConditionRow(
                  'Temperature',
                  '${sensorService.currentData!.temperature.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  Colors.red,
                ),
                const SizedBox(height: 8),
                _buildConditionRow(
                  'Humidity',
                  '${sensorService.currentData!.humidity.toStringAsFixed(1)}%',
                  Icons.water_drop,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildConditionRow(
                  'Soil Moisture',
                  '${sensorService.currentData!.soilMoisture.toStringAsFixed(1)}%',
                  Icons.grass,
                  Colors.green,
                ),
              ] else
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildConditionRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
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
}
