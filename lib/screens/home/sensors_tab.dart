// ============================================================
// FILE: lib/screens/home/sensors_tab.dart
// REDESIGNED: Professional sensor dashboard with:
//   - Real-time readings with status indicators
//   - Line charts for Temperature, Humidity, Soil Moisture
//   - NPK shown as arc gauges (NOT line charts — NPK changes
//     slowly so a chart would be a flat boring line; gauges
//     are the correct visualization for slow-changing nutrients)
//   - Historical log table at the bottom
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_data.dart';

class SensorsTab extends StatelessWidget {
  const SensorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorService>(
      builder: (context, sensorService, child) {
        final data    = sensorService.currentData;
        final history = sensorService.historicalData;

        if (data == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => sensorService.refreshData(),
          color: const Color(0xFF4CAF50),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Section: Live Readings ──────────────────────────────
              _sectionHeader('Live Readings', Icons.sensors, const Color(0xFF4CAF50)),
              const SizedBox(height: 10),

              // Temperature + Humidity row
              Row(children: [
                Expanded(child: _liveCard(
                  label:    'Temperature',
                  value:    '${data.temperature.toStringAsFixed(1)}°C',
                  icon:     Icons.thermostat,
                  color:    _tempColor(data.temperature),
                  status:   _tempStatus(data.temperature),
                  subLabel: 'Optimal: 20–30°C',
                )),
                const SizedBox(width: 12),
                Expanded(child: _liveCard(
                  label:    'Humidity',
                  value:    '${data.humidity.toStringAsFixed(1)}%',
                  icon:     Icons.water_drop,
                  color:    _humidColor(data.humidity),
                  status:   _humidStatus(data.humidity),
                  subLabel: 'Optimal: 50–80%',
                )),
              ]),
              const SizedBox(height: 12),

              // Soil moisture full-width
              _liveCard(
                label:    'Soil Moisture',
                value:    '${data.soilMoisture.toStringAsFixed(1)}%',
                icon:     Icons.grass,
                color:    _moistureColor(data.soilMoisture),
                status:   _moistureStatus(data.soilMoisture),
                subLabel: 'Optimal: 40–70%',
                fullWidth: true,
              ),
              const SizedBox(height: 24),

              // ── Section: Soil Nutrients (NPK) ──────────────────────
              _sectionHeader('Soil Nutrients (NPK)', Icons.science, Colors.orange),
              const SizedBox(height: 4),
              const Text(
                'NPK levels change slowly — shown as gauges, not charts.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(child: _nutrientCard(
                  symbol: 'N',
                  label:  'Nitrogen',
                  value:  data.nitrogen,
                  max:    140,
                  color:  Colors.green.shade600,
                  low:    40, high: 110,
                )),
                const SizedBox(width: 12),
                Expanded(child: _nutrientCard(
                  symbol: 'P',
                  label:  'Phosphorus',
                  value:  data.phosphorus,
                  max:    100,
                  color:  Colors.orange,
                  low:    30, high: 80,
                )),
                const SizedBox(width: 12),
                Expanded(child: _nutrientCard(
                  symbol: 'K',
                  label:  'Potassium',
                  value:  data.potassium,
                  max:    100,
                  color:  Colors.purple,
                  low:    30, high: 80,
                )),
              ]),
              const SizedBox(height: 24),

              // ── Section: Charts ─────────────────────────────────────
              _sectionHeader('History Charts', Icons.show_chart, Colors.blue),
              const SizedBox(height: 10),

              _chartCard(
                title:   'Temperature (°C)',
                color:   Colors.red,
                icon:    Icons.thermostat,
                data:    history.map((e) => e.temperature).toList(),
                minY:    15,
                maxY:    40,
                unit:    '°C',
              ),
              const SizedBox(height: 12),

              _chartCard(
                title:   'Humidity (%)',
                color:   Colors.blue,
                icon:    Icons.water_drop,
                data:    history.map((e) => e.humidity).toList(),
                minY:    0,
                maxY:    100,
                unit:    '%',
              ),
              const SizedBox(height: 12),

              _chartCard(
                title:   'Soil Moisture (%)',
                color:   Colors.brown,
                icon:    Icons.grass,
                data:    history.map((e) => e.soilMoisture).toList(),
                minY:    0,
                maxY:    100,
                unit:    '%',
              ),
              const SizedBox(height: 24),

              // ── Section: Historical Log ─────────────────────────────
              _sectionHeader('Historical Log', Icons.history, Colors.teal),
              const SizedBox(height: 10),
              _historyLog(history),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1a1a1a),
      )),
    ]);
  }

  // ── Live reading card ───────────────────────────────────────────────────────
  Widget _liveCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String status,
    required String subLabel,
    bool fullWidth = false,
  }) {
    final isGood = status == 'Optimal';
    final statusColor = isGood ? Colors.green : (status == 'Low' ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color,
            )),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isGood ? Icons.check_circle : Icons.warning_amber,
                    size: 11, color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(status, style: TextStyle(
                    fontSize: 11, color: statusColor, fontWeight: FontWeight.w600,
                  )),
                ]),
              ),
              const SizedBox(width: 8),
              Text(subLabel, style: const TextStyle(
                fontSize: 10, color: Colors.grey,
              )),
            ]),
          ],
        )),
      ]),
    );
  }

  // ── Nutrient card with progress bar ─────────────────────────────────────────
  Widget _nutrientCard({
    required String symbol,
    required String label,
    required double value,
    required double max,
    required Color color,
    required double low,
    required double high,
  }) {
    final pct = (value / max).clamp(0.0, 1.0);
    final isLow  = value < low;
    final isHigh = value > high;
    final statusColor = isLow ? Colors.orange : (isHigh ? Colors.red : Colors.green);
    final statusText  = isLow ? 'Low' : (isHigh ? 'High' : 'Good');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Column(children: [
        // Symbol circle
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(symbol, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color,
            )),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(
          fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 4),
        Text('${value.toStringAsFixed(0)}', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: color,
        )),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusText, style: TextStyle(
            fontSize: 10, color: statusColor, fontWeight: FontWeight.w700,
          )),
        ),
      ]),
    );
  }

  // ── Chart card ──────────────────────────────────────────────────────────────
  Widget _chartCard({
    required String title,
    required Color color,
    required IconData icon,
    required List<double> data,
    required double minY,
    required double maxY,
    required String unit,
  }) {
    final hasData = data.length >= 2;
    final current = data.isNotEmpty ? data.last : 0.0;
    final avg     = data.isNotEmpty ? data.reduce((a, b) => a + b) / data.length : 0.0;
    final minVal  = data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) : 0.0;
    final maxVal  = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
          )),
          const Spacer(),
          Text('${current.toStringAsFixed(1)}$unit', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: color,
          )),
        ]),
        const SizedBox(height: 4),

        // Stats row
        if (hasData)
          Row(children: [
            _statChip('Avg', '${avg.toStringAsFixed(1)}$unit', Colors.grey),
            const SizedBox(width: 8),
            _statChip('Min', '${minVal.toStringAsFixed(1)}$unit', Colors.blue),
            const SizedBox(width: 8),
            _statChip('Max', '${maxVal.toStringAsFixed(1)}$unit', Colors.red),
            const Spacer(),
            Text('${data.length} readings',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),

        const SizedBox(height: 12),

        // Chart
        if (!hasData)
          SizedBox(
            height: 120,
            child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, color: Colors.grey.shade300, size: 40),
                const SizedBox(height: 6),
                Text('Waiting for data...', style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 12,
                )),
              ],
            )),
          )
        else
          SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.grey.withOpacity(0.12), strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: (maxY - minY) / 4,
                    getTitlesWidget: (v, meta) => Text(
                      v.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: color,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            )),
          ),
      ]),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(value, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: color,
      )),
    ]);
  }

  // ── Historical log table ────────────────────────────────────────────────────
  Widget _historyLog(List<SensorData> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('No history yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Show last 15 entries, newest first
    final entries = history.reversed.take(15).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            _headerCell('Time',     flex: 2),
            _headerCell('Temp',     flex: 1),
            _headerCell('Humidity', flex: 1),
            _headerCell('Moisture', flex: 1),
            _headerCell('N/P/K',    flex: 2),
          ]),
        ),
        const Divider(height: 1),
        // Table rows
        ...entries.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Container(
            color: i.isEven ? Colors.white : Colors.grey.shade50.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              Expanded(flex: 2, child: Text(
                DateFormat('HH:mm:ss').format(e.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              )),
              _valueCell('${e.temperature.toStringAsFixed(1)}°', _tempColor(e.temperature), flex: 1),
              _valueCell('${e.humidity.toStringAsFixed(1)}%',    _humidColor(e.humidity),   flex: 1),
              _valueCell('${e.soilMoisture.toStringAsFixed(1)}%',_moistureColor(e.soilMoisture), flex: 1),
              Expanded(flex: 2, child: Text(
                '${e.nitrogen.toStringAsFixed(0)} / ${e.phosphorus.toStringAsFixed(0)} / ${e.potassium.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
              )),
            ]),
          );
        }).toList(),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          child: Text(
            'Showing last ${entries.length} of ${history.length} entries',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ]),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey,
      )),
    );
  }

  Widget _valueCell(String text, Color color, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, color: color,
      )),
    );
  }

  // ── Color + status helpers ───────────────────────────────────────────────────
  Color _tempColor(double t) {
    if (t < 15) return Colors.blue;
    if (t > 35) return Colors.red;
    return Colors.orange;
  }

  String _tempStatus(double t) {
    if (t < 15) return 'Low';
    if (t > 35) return 'High';
    return 'Optimal';
  }

  Color _humidColor(double h) {
    if (h < 40) return Colors.orange;
    if (h > 85) return Colors.blue.shade700;
    return Colors.blue;
  }

  String _humidStatus(double h) {
    if (h < 40) return 'Low';
    if (h > 85) return 'High';
    return 'Optimal';
  }

  Color _moistureColor(double m) {
    if (m < 30) return Colors.red;
    if (m < 40) return Colors.orange;
    if (m > 75) return Colors.blue;
    return Colors.green;
  }

  String _moistureStatus(double m) {
    if (m < 30) return 'Critical';
    if (m < 40) return 'Low';
    if (m > 75) return 'High';
    return 'Optimal';
  }
}