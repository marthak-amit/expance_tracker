import 'expense_with_category.dart';

class MonthGroup {
  const MonthGroup(this.month, this.items);

  /// First day of the month.
  final DateTime month;
  final List<ExpenseWithCategory> items;

  double get total => items.fold(0.0, (sum, e) => sum + e.expense.amount);
}

/// Groups by calendar month, keeping the input order (newest first in, newest
/// first out).
List<MonthGroup> groupByMonth(Iterable<ExpenseWithCategory> expenses) {
  final groups = <DateTime, List<ExpenseWithCategory>>{};
  for (final e in expenses) {
    final d = e.expense.date;
    groups.putIfAbsent(DateTime(d.year, d.month), () => []).add(e);
  }
  return [for (final g in groups.entries) MonthGroup(g.key, g.value)];
}
