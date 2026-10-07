/// Maps a merchant (and the raw receipt/SMS text it came from) to a category
/// name from `CategoryNames`, with a confidence in [0, 1].
abstract class ExpenseCategorizer {
  Future<(String category, double confidence)> classify(
    String merchant,
    String rawText,
  );
}
