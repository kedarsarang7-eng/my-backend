import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart'; // Kept as reference if needed

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
      script: TextRecognitionScript
          .latin); // Or .devanagari if needed for Indian langs

  Future<String> scanImage(String imagePath) async {
    if (kIsWeb) {
      debugPrint(
          "OCR Web: Backend integration required. Returning Mock Data for UI testing.");
      return "Web Mock Data: Shop X, Total 100";
    } else {
      try {
        debugPrint("Starting Google ML Kit OCR on: $imagePath");
        final inputImage = InputImage.fromFilePath(imagePath);
        final recognizedText = await _recognizer.processImage(inputImage);

        final text = recognizedText.text;
        debugPrint(
            "ML Kit Result: ${text.substring(0, text.length > 100 ? 100 : text.length)}...");
        return text;
      } catch (e) {
        debugPrint("ML Kit Error: $e");
        return "Failed to scan image.";
      }
    }
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
