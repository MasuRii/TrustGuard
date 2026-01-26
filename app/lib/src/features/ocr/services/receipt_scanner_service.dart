import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_data.dart';
import '../utils/receipt_parser.dart';

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<ReceiptData?> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      return ReceiptParser.parseReceipt(recognizedText.text);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
