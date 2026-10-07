import 'model_download_manager.dart';
import 'query_intent.dart';

abstract class LlmService {
  /// Turns a natural-language question into a validated [QueryIntent].
  ///
  /// The model must never compute or state totals: it only classifies the
  /// question. Callers run `IntentQueryRunner` (a drift query) to get numbers.
  Future<QueryIntent> parseQuery(String q);
}

/// PHASE 2 STUB - not implemented.
///
/// Intended design: wraps a flutter_gemma inference session. `parseQuery`
/// prompts the model with today's date and the category list, asks for one JSON
/// object matching [QueryIntent], then validates it with `QueryIntent.parse`
/// (throwing `QueryIntentFormatException` on anything off-schema, optionally
/// retrying once). Fails fast if the model is not downloaded.
class GemmaLlmService implements LlmService {
  GemmaLlmService(this._downloads);

  // ignore: unused_field
  final ModelDownloadManager _downloads;

  @override
  Future<QueryIntent> parseQuery(String q) =>
      throw UnimplementedError('GemmaLlmService.parseQuery');
}
