import 'expense_categorizer.dart';
import 'merchant_normalizer.dart';

/// Read side of the `merchant_overrides` table.
abstract class MerchantOverrideStore {
  /// Category name the user previously chose for [merchantNormalized], if any.
  Future<String?> categoryNameFor(String merchantNormalized);
}

/// Decorator: a user correction always beats the wrapped categorizer, whichever
/// implementation (keyword, TFLite, ...) that is.
class OverrideFirstCategorizer implements ExpenseCategorizer {
  OverrideFirstCategorizer({required this.delegate, required this.overrides});

  final ExpenseCategorizer delegate;
  final MerchantOverrideStore overrides;

  @override
  Future<(String, double)> classify(String merchant, String rawText) async {
    final key = normalizeMerchant(merchant);
    if (key.isNotEmpty) {
      final overridden = await overrides.categoryNameFor(key);
      if (overridden != null) return (overridden, 1.0);
    }
    return delegate.classify(merchant, rawText);
  }
}
