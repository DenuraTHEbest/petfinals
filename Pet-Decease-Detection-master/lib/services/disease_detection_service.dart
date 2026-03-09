import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class DiseaseDetectionService {
  // The special alias for the Android Emulator to reach your computer's localhost
  final String _baseUrl = "http://10.0.2.2:8000/analyze-pet";

  Future<Map<String, dynamic>> analyzePetImage(File image) async {
    try {
      // Create a multi-part request
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      // Attach the image file
      var stream = http.ByteStream(image.openRead());
      var length = await image.length();
      var multipartFile = http.MultipartFile(
        'file', // This must match the 'file: UploadFile' name in your Python code
        stream,
        length,
        filename: basename(image.path),
      );

      request.files.add(multipartFile);

      // Send the request to your Python backend
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        // Return the parsed JSON from your backend
        return json.decode(responseData.body);
      } else {
        return {
          "species": "Error",
          "diagnosis": "Server returned status: ${response.statusCode}",
          "analysis_source": "Network"
        };
      }
    } catch (e) {
      return {
        "species": "Error",
        "diagnosis": "Connection failed. Is the backend running? Error: $e",
        "analysis_source": "Network"
      };
    }
  }
}