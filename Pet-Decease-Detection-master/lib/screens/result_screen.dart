import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detected: ${result['species']}", 
                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Source: ${result['analysis_source']}", 
                 style: const TextStyle(color: Colors.blueGrey)),
            const Divider(height: 40),
            const Text("Diagnosis:", 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("${result['diagnosis']}", 
                 style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}