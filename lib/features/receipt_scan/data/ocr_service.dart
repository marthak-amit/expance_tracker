import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class OcrService {
  Future<String> recognizeText(String imagePath);
}

/// On-device ML Kit (Latin script). Receipts are English/Latin; Devanagari
/// would need `TextRecognitionScript.devanagiri`.
class MlKitOcrService implements OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText(String imagePath) async {
    final result = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return result.text;
  }

  void dispose() => _recognizer.close();
}
