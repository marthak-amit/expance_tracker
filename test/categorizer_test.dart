import 'package:expance_tracker/core/database/default_categories.dart';
import 'package:expance_tracker/features/ai/categorizer/keyword_categorizer.dart';
import 'package:expance_tracker/features/ai/categorizer/override_first_categorizer.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOverrides implements MerchantOverrideStore {
  _FakeOverrides(this.map);
  final Map<String, String> map;
  @override
  Future<String?> categoryNameFor(String merchantNormalized) async =>
      map[merchantNormalized];
}

void main() {
  final keyword = KeywordCategorizer();

  group('KeywordCategorizer', () {
    const cases = {
      'Swiggy': CategoryNames.food,
      'ZOMATO LTD': CategoryNames.food,
      'Domino\'s Pizza': CategoryNames.food,
      'Uber Eats': CategoryNames.food, // longer keyword beats "uber"
      'Uber India': CategoryNames.transport,
      'OLA CABS': CategoryNames.transport,
      'BigBasket': CategoryNames.groceries,
      'Swiggy Instamart': CategoryNames.groceries, // beats "swiggy"
      'Amazon.in': CategoryNames.shopping,
      'Amazon Pay': CategoryNames.bills, // beats "amazon"
      'Flipkart': CategoryNames.shopping,
      'Reliance Jio': CategoryNames.bills,
      'Airtel Postpaid': CategoryNames.bills,
      'Netflix': CategoryNames.entertainment,
      'Apollo Pharmacy': CategoryNames.health,
      'IRCTC': CategoryNames.travel,
    };
    cases.forEach((merchant, expected) {
      test('$merchant -> $expected', () async {
        final (category, confidence) = await keyword.classify(merchant, '');
        expect(category, expected);
        expect(confidence, KeywordCategorizer.merchantMatchConfidence);
      });
    });

    test(
      'matches whole words only ("ola" is not inside "Cola Corner")',
      () async {
        final (category, _) = await keyword.classify('Cola Corner', '');
        expect(category, CategoryNames.other);
      },
    );

    test('falls back to raw text with lower confidence', () async {
      final (category, confidence) = await keyword.classify(
        'Unknown Shop',
        'Biryani x2\nThank you',
      );
      expect(category, CategoryNames.food);
      expect(confidence, KeywordCategorizer.rawTextMatchConfidence);
    });

    test('no match -> Other with zero confidence', () async {
      expect(await keyword.classify('Xyz Traders', ''), (
        CategoryNames.other,
        0.0,
      ));
    });
  });

  group('OverrideFirstCategorizer', () {
    final categorizer = OverrideFirstCategorizer(
      delegate: keyword,
      overrides: _FakeOverrides({'swiggy': CategoryNames.groceries}),
    );

    test(
      'override beats the delegate, matched on normalized merchant',
      () async {
        expect(await categorizer.classify('  SWIGGY! ', ''), (
          CategoryNames.groceries,
          1.0,
        ));
      },
    );

    test('no override -> delegate answer', () async {
      final (category, _) = await categorizer.classify('Zomato', '');
      expect(category, CategoryNames.food);
    });
  });
}
