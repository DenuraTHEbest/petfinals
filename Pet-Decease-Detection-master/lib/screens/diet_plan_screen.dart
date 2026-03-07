import 'package:flutter/material.dart';

class DietPlanScreen extends StatelessWidget {
  const DietPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Plans')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                title: Text('Overweight Plan 🐕'),
                subtitle: Text(
                    '• High protein\n• Low fat\n• Daily walking\n• Controlled portions'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Underweight Plan 🐾'),
                subtitle: Text(
                    '• High calories\n• Healthy fats\n• Frequent meals'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
