import 'expense_categorizer.dart';

/// PHASE 2 STUB - not implemented.
///
/// Intended design: bag-of-words / small text classifier exported to TFLite.
/// - [modelAsset] holds the model, [vocabAsset] the token -> index vocabulary
///   (one token per line, line number = index).
/// - `classify` tokenizes `merchant` (plus a truncated `rawText`) with the same
///   normalizer used in training, runs the interpreter (tflite_flutter), and
///   returns the arg-max category name with its softmax probability.
/// - Output labels must be `CategoryNames` values.
///
/// To enable: add both files under `assets/`, declare them in pubspec.yaml,
/// then swap this in as the delegate in `categorizerProvider`.
class TfliteCategorizer implements ExpenseCategorizer {
  static const modelAsset = 'assets/categorizer.tflite';
  static const vocabAsset = 'assets/vocab.txt';

  /// Loads the interpreter and vocabulary. Call once before [classify].
  Future<void> load() => throw UnimplementedError('TfliteCategorizer.load');

  @override
  Future<(String, double)> classify(String merchant, String rawText) =>
      throw UnimplementedError('TfliteCategorizer.classify');
}
