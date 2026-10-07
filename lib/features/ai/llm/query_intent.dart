import 'dart:convert';

enum QueryAggregate { sum, count, list }

class QueryIntentFormatException implements Exception {
  QueryIntentFormatException(this.message);
  final String message;
  @override
  String toString() => 'QueryIntentFormatException: $message';
}

/// Structured form of a natural-language question like "how much did I spend
/// on food last month?". The LLM only fills this in; numbers are produced by
/// running a drift query from it (see `IntentQueryRunner`), never by the model.
class QueryIntent {
  const QueryIntent({
    required this.aggregate,
    this.category,
    this.merchant,
    this.from,
    this.to,
    this.limit,
  });

  final QueryAggregate aggregate;

  /// A `CategoryNames` value, canonical casing.
  final String? category;
  final String? merchant;

  /// Inclusive date range.
  final DateTime? from;
  final DateTime? to;

  /// Only meaningful for [QueryAggregate.list].
  final int? limit;

  static const _allowedKeys = {
    'aggregate',
    'category',
    'merchant',
    'from',
    'to',
    'limit',
  };

  /// Parses model output. Tolerates a surrounding Markdown code fence, nothing
  /// else: anything off-schema throws [QueryIntentFormatException].
  factory QueryIntent.parse(
    String raw, {
    required Set<String> knownCategories,
  }) {
    var text = raw.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(text);
    if (fence != null) text = fence.group(1)!;

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (e) {
      throw QueryIntentFormatException('not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw QueryIntentFormatException('expected a JSON object');
    }
    return QueryIntent.fromJson(decoded, knownCategories: knownCategories);
  }

  factory QueryIntent.fromJson(
    Map<String, dynamic> json, {
    required Set<String> knownCategories,
  }) {
    final unknown = json.keys.where((k) => !_allowedKeys.contains(k));
    if (unknown.isNotEmpty) {
      throw QueryIntentFormatException('unknown keys: ${unknown.join(', ')}');
    }

    final aggregateName = _string(json, 'aggregate');
    final aggregate = QueryAggregate.values.where(
      (a) => a.name == aggregateName,
    );
    if (aggregate.isEmpty) {
      throw QueryIntentFormatException('invalid aggregate: $aggregateName');
    }

    String? category;
    final rawCategory = _optionalString(json, 'category');
    if (rawCategory != null) {
      category = knownCategories
          .where((c) => c.toLowerCase() == rawCategory.toLowerCase())
          .firstOrNull;
      if (category == null) {
        throw QueryIntentFormatException('unknown category: $rawCategory');
      }
    }

    final from = _optionalDate(json, 'from');
    final to = _optionalDate(json, 'to');
    if (from != null && to != null && to.isBefore(from)) {
      throw QueryIntentFormatException('"to" is before "from"');
    }

    int? limit;
    if (json['limit'] != null) {
      final l = json['limit'];
      if (l is! int || l < 1 || l > 100) {
        throw QueryIntentFormatException('limit must be an integer in 1..100');
      }
      limit = l;
    }

    return QueryIntent(
      aggregate: aggregate.first,
      category: category,
      merchant: _optionalString(json, 'merchant'),
      from: from,
      to: to,
      limit: limit,
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is! String || v.trim().isEmpty) {
      throw QueryIntentFormatException('"$key" must be a non-empty string');
    }
    return v.trim();
  }

  static String? _optionalString(Map<String, dynamic> json, String key) =>
      json[key] == null ? null : _string(json, key);

  static DateTime? _optionalDate(Map<String, dynamic> json, String key) {
    final v = _optionalString(json, key);
    if (v == null) return null;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
      throw QueryIntentFormatException('"$key" must be YYYY-MM-DD, got $v');
    }
    final d = DateTime.tryParse(v);
    if (d == null || d.toIso8601String().substring(0, 10) != v) {
      throw QueryIntentFormatException('"$key" is not a real date: $v');
    }
    return d;
  }
}
