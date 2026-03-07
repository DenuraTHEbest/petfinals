import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightChartScreen extends StatelessWidget {
  const WeightChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<double> weights = [10.5, 11.0, 11.8, 12.5, 13.2];

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Weight Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Weight Progress (kg)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: weights
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                          e.key.toDouble(),
                          e.value.toDouble(),
                        ),
                      )
                          .toList(),
                      isCurved: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Status: Overweight ⚠️',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
