import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../domain/parsed_receipt.dart';

/// A parsed receipt plus the categorizer's suggestion for it.
class ScannedReceipt {
  const ScannedReceipt({
    required this.parsed,
    required this.category,
    required this.confidence,
  });
  final ParsedReceipt parsed;
  final String category;
  final double confidence;
}

class ReceiptScanService {
  ReceiptScanService(this._ref);
  final Ref _ref;

  /// Picks an image, runs OCR + parsing + categorization. Null if the user
  /// cancelled the picker.
  Future<ScannedReceipt?> scan(ImageSource source) async {
    final file = await _ref
        .read(imagePickerProvider)
        .pickImage(
          source: source,
          maxWidth: 2400, // plenty for OCR, keeps ML Kit fast and memory low
          imageQuality: 90,
        );
    if (file == null) return null;

    final text = await _ref.read(ocrServiceProvider).recognizeText(file.path);
    final parsed = _ref.read(receiptParserProvider).parse(text);
    final (category, confidence) = await _ref
        .read(categorizerProvider)
        .classify(parsed.merchant ?? '', text);
    return ScannedReceipt(
      parsed: parsed,
      category: category,
      confidence: confidence,
    );
  }
}

final receiptScanServiceProvider = Provider<ReceiptScanService>(
  ReceiptScanService.new,
);
