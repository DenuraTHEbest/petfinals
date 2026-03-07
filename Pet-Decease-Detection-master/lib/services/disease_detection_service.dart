import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:http/http.dart' as http; // For your custom backend API calls

class DiseaseDetectionService {
  
  Future<String> analyzePetImage(File image) async {
    // 1. Send image to Model 1 (Your custom API endpoint / TFLite)
    String petType = await _runModel1(image);

    // 2. Branching Logic
    if (petType.toLowerCase() == 'dog' || petType.toLowerCase() == 'cat') {
      // Send to Model 2
      return await _runModel2(image, petType);
    } else {
      // Send to Gemini
      return await _runGeminiAnalysis(image, petType);
    }
  }

  Future<String> _runModel1(File image) async {
    // TODO: Implement HTTP POST request to your Python backend for Model 1
    // Example: return "cow"; 
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
    return "dog"; // Hardcoded for testing, replace with actual API call
  }

  Future<String> _runModel2(File image, String petType) async {
    // TODO: Implement HTTP POST request to your Python backend for Model 2
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
    return "The $petType appears healthy, but monitor for mild dermatitis.";
  }

  Future<String> _runGeminiAnalysis(File image, String petType) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('Gemini API key not found in .env');

    final model = GenerativeModel(
      model: 'gemini-1.5-pro', // or flash depending on your needs
      apiKey: apiKey,
    );

    final prompt = TextPart("Analyze this image of a $petType. Identify any visible signs of disease or health issues. Provide a concise, professional diagnosis.");
    final imageBytes = await image.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    return response.text ?? "Could not generate analysis from Gemini.";
  }
}