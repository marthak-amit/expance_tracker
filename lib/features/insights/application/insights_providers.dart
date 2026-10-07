import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../expenses/domain/expense_with_category.dart';

/// First day of the month shown on the insights screen.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void shift(int months) => state = DateTime(state.year, state.month + months);
}

final selectedMonthProvider = NotifierProvider<SelectedMonth, DateTime>(
  SelectedMonth.new,
);

final categoryTotalsProvider = StreamProvider.autoDispose<List<CategoryTotal>>((
  ref,
) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(expenseRepositoryProvider)
      .watchCategoryTotals(
        from: month,
        to: DateTime(month.year, month.month + 1),
      );
});
