import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/disease_detection_service.dart'; 

class PlaceholderScreen extends StatefulWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  
  // We use 'dynamic' so it can hold either a "Status String" or the "Result Map"
  dynamic _analysisResult = "Select an image to begin"; 
  
  final ImagePicker _picker = ImagePicker();
  final DiseaseDetectionService _detectionService = DiseaseDetectionService();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _analysisResult = "Ready to analyze... 🐾";
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = "Connecting to server...";
    });

    try {
      final result = await _detectionService.analyzePetImage(_selectedImage!);
      setState(() {
        _analysisResult = result; // This is now the Map from your backend
      });
    } catch (e) {
      setState(() {
        _analysisResult = "Connection Error: Ensure backend is running.";
      });
    } finally {
      setState(() {
        _isAnalyzing = false; // This stops the loading spinner
      });
    }
  }

  // --- NEW: This helper function prevents the UI crash ---
  Widget _buildResultDisplay() {
    if (_analysisResult is String) {
      return Text(
        _analysisResult,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      );
    } else if (_analysisResult is Map) {
      // Extracting the data from your backend JSON
      final species = _analysisResult['species'] ?? "Unknown";
      final diagnosis = _analysisResult['diagnosis'] ?? "No diagnosis";
      final source = _analysisResult['analysis_source'] ?? "AI";

      return Column(
        children: [
          Text("Detected: $species", 
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Divider(height: 20),
          Text(diagnosis, 
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
          const SizedBox(height: 10),
          Text("Source: $source", 
               style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      );
    }
    return const Text("Waiting for data...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!, height: 300, fit: BoxFit.cover),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.pets, size: 80, color: Colors.grey)),
              ),
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Analyze Button
            ElevatedButton(
              onPressed: _isAnalyzing || _selectedImage == null ? null : _analyzeImage,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isAnalyzing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Detect Disease'),
            ),
            const SizedBox(height: 30),
            
            // Result Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: _buildResultDisplay(), // Uses the helper widget
            ),
          ],
        ),
      ),
    );
  }
}