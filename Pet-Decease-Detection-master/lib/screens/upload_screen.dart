import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/primary_button.dart';
import 'result_screen.dart';
import '../services/disease_detection_service.dart';
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? imageFile;
  final DiseaseDetectionService _apiService = DiseaseDetectionService();

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(),
                ),
                child: imageFile == null
                    ? const Center(child: Text('Tap to select image'))
                    : Image.file(imageFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Analyze',
              onPressed: imageFile == null
                  ? null
                  : () async {
                      // 1. Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      // 2. Call the service (returns a Map now)
                      final result = await DiseaseDetectionService().analyzePetImage(imageFile!);

                      // 3. Remove loading indicator
                      if (!mounted) return;
                      Navigator.pop(context);

                      // 4. Navigate to ResultScreen and pass the Map
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(result: result),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
