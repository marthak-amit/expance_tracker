import 'package:expance_tracker/features/ai/llm/query_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cats = {'Food & Dining', 'Transport'};
  QueryIntent parse(String s) => QueryIntent.parse(s, knownCategories: cats);

  test('valid intent, category canonicalised, code fence tolerated', () {
    final i = parse(
      '```json\n{"aggregate":"sum","category":"food & dining",'
      '"from":"2024-03-01","to":"2024-03-31"}\n```',
    );
    expect(i.aggregate, QueryAggregate.sum);
    expect(i.category, 'Food & Dining');
    expect(i.from, DateTime(2024, 3, 1));
    expect(i.to, DateTime(2024, 3, 31));
  });

  for (final bad in {
    'not json': 'the total is 500',
    'array': '[1]',
    'unknown key (e.g. model-supplied total)':
        '{"aggregate":"sum","total":500}',
    'bad aggregate': '{"aggregate":"average"}',
    'unknown category': '{"aggregate":"sum","category":"Pets"}',
    'bad date': '{"aggregate":"sum","from":"2024-02-31"}',
    'range reversed':
        '{"aggregate":"sum","from":"2024-03-02","to":"2024-03-01"}',
    'limit out of range': '{"aggregate":"list","limit":0}',
  }.entries) {
    test('rejects ${bad.key}', () {
      expect(
        () => parse(bad.value),
        throwsA(isA<QueryIntentFormatException>()),
      );
    });
  }
}
