import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class VisionService {
  static final VisionService instance = VisionService._();
  VisionService._();

  Future<Map<String, dynamic>> extractFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (recognizedText.text.isEmpty) {
        return {'rawText': '', 'error': 'No text detected'};
      }

      return {'rawText': recognizedText.text, 'error': null};
    } catch (e) {
      return {'rawText': '', 'error': 'OCR failed: $e'};
    }
  }

  Future<Map<String, dynamic>> extractFromBytes(List<int> bytes) async {
    final tempFile = File('${Directory.systemTemp.path}/ocr_temp.jpg');
    await tempFile.writeAsBytes(bytes);
    final result = await extractFromImage(tempFile);
    await tempFile.delete();
    return result;
  }
}