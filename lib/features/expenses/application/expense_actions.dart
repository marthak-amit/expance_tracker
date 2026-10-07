import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../ai/categorizer/merchant_normalizer.dart';

/// What the add / confirm form hands back on submit.
class ExpenseFormResult {
  const ExpenseFormResult({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.category,
    required this.confidence,
    required this.categoryCorrected,
  });

  final double amount;
  final String merchant;
  final DateTime date;
  final Category category;

  /// Categorizer confidence, or 1.0 when the user chose the category.
  final double confidence;

  /// The user picked a different category than the one suggested.
  final bool categoryCorrected;
}

class ExpenseActions {
  ExpenseActions(this._ref);
  final Ref _ref;

  /// Saves the expense and, if the user overrode the suggested category,
  /// remembers that choice for this merchant.
  Future<void> save(
    ExpenseFormResult form, {
    required ExpenseSource source,
    String? rawText,
  }) async {
    final repo = _ref.read(expenseRepositoryProvider);
    await repo.addExpense(
      amount: form.amount,
      merchant: form.merchant,
      categoryId: form.category.id,
      date: form.date,
      source: source,
      rawText: rawText,
      confidence: form.confidence,
    );
    final key = normalizeMerchant(form.merchant);
    if (form.categoryCorrected && key.isNotEmpty) {
      await repo.upsertOverride(
        merchantNormalized: key,
        categoryId: form.category.id,
      );
    }
  }

  Future<void> delete(int expenseId) =>
      _ref.read(expenseRepositoryProvider).deleteExpense(expenseId);
}

final expenseActionsProvider = Provider<ExpenseActions>(ExpenseActions.new);
