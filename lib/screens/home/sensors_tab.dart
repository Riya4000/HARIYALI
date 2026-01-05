//============================================================================
// SENSORS TAB - Detailed sensor readings with charts
//============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/sensor_service.dart';

class SensorsTab extends StatelessWidget {
const SensorsTab({super.key});

@override
Widget build(BuildContext context) {
return Consumer<SensorService>(
builder: (context, sensorService, child) {
final data = sensorService.currentData;
final history = sensorService.historicalData;

if (data == null) {
return const Center(
child: CircularProgressIndicator(
color: Color(0xFF4CAF50),
),
);
}

return RefreshIndicator(
onRefresh: () => sensorService.refreshData(),
color: const Color(0xFF4CAF50),
child: ListView(
padding: const EdgeInsets.all(16),
children: [
// Temperature chart
_buildChartCard(
'Temperature (°C)',
Colors.red,
history.map((e) => e.temperature).toList(),
Icons.thermostat,
),
const SizedBox(height: 16),

// Humidity chart
_buildChartCard(
'Humidity (%)',
Colors.blue,
history.map((e) => e.humidity).toList(),
Icons.water_drop,
),
const SizedBox(height: 16),

// Soil moisture chart
_buildChartCard(
'Soil Moisture (%)',
Colors.brown,
history.map((e) => e.soilMoisture).toList(),
Icons.grass,
),
const SizedBox(height: 16),

// pH chart
_buildChartCard(
'pH Level',
Colors.purple,
history.map((e) => e.pH).toList(),
Icons.science,
),
],
),
);
},
);
}

Widget _buildChartCard(String title, Color color, List<double> data, IconData icon) {
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
const SizedBox(width: 12),
Text(
title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const Spacer(),
Text(
data.isNotEmpty ? data.last.toStringAsFixed(1) : '0',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: color,
),
),
],
),
const SizedBox(height: 16),

// Chart
SizedBox(
height: 150,
child: LineChart(
LineChartData(
gridData: FlGridData(show: false),
titlesData: FlTitlesData(show: false),
borderData: FlBorderData(show: false),
lineBarsData: [
LineChartBarData(
spots: data.asMap().entries.map((entry) {
return FlSpot(entry.key.toDouble(), entry.value);
}).toList(),
isCurved: true,
color: color,
barWidth: 3,
dotData: FlDotData(show: false),
belowBarData: BarAreaData(
show: true,
color: color.withOpacity(0.1),
),
),
],
),
),
),

const SizedBox(height: 8),
const Text(
'Last 24 hours',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
);
}
}

