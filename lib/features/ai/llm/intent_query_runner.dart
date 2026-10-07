import 'query_intent.dart';

/// Result of executing a [QueryIntent]; numbers come from SQL, not the LLM.
class IntentResult {
  const IntentResult({this.total, this.count, this.rows = const []});
  final double? total;
  final int? count;
  final List<Object> rows;
}

/// PHASE 2 STUB - not implemented.
///
/// Will translate a [QueryIntent] into a drift query on `ExpenseRepository`
/// (sum / count / list, filtered by category, merchant and date range).
class IntentQueryRunner {
  Future<IntentResult> run(QueryIntent intent) =>
      throw UnimplementedError('IntentQueryRunner.run');
}
