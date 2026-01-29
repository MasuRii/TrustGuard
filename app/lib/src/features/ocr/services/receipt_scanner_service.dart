import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/utils/platform_utils.dart';
import '../models/receipt_data.dart';
import '../utils/receipt_parser.dart';

/// Service for scanning receipts using OCR.
///
/// Note: OCR is only supported on mobile platforms (Android/iOS) where
/// Google ML Kit is available. On other platforms, [scanReceipt] returns null.
class ReceiptScannerService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer();
    return _textRecognizer!;
  }

  /// Whether OCR scanning is supported on the current platform.
  bool get isSupported => PlatformUtils.supportsCameraFeatures;

  /// Scans a receipt image and extracts data.
  ///
  /// Returns null if OCR is not supported on this platform or if parsing fails.
  Future<ReceiptData?> scanReceipt(String imagePath) async {
    // OCR is only available on mobile platforms
    if (!isSupported) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText = await _recognizer.processImage(
        inputImage,
      );

      return ReceiptParser.parseReceipt(recognizedText.text);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
