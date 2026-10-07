import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../ai/categorizer/override_first_categorizer.dart';
import '../domain/expense_with_category.dart';

class ExpenseRepository implements MerchantOverrideStore {
  ExpenseRepository(this._db);

  final AppDatabase _db;

  $CategoriesTable get _categories => _db.categories;
  $ExpensesTable get _expenses => _db.expenses;
  $MerchantOverridesTable get _overrides => _db.merchantOverrides;

  Stream<List<Category>> watchCategories() => (_db.select(
    _categories,
  )..orderBy([(c) => OrderingTerm.asc(c.id)])).watch();

  Stream<List<ExpenseWithCategory>> watchExpenses() {
    final query =
        _db.select(_expenses).join([
          innerJoin(
            _categories,
            _categories.id.equalsExp(_expenses.categoryId),
          ),
        ])..orderBy([
          OrderingTerm.desc(_expenses.date),
          OrderingTerm.desc(_expenses.id),
        ]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          ExpenseWithCategory(r.readTable(_expenses), r.readTable(_categories)),
      ],
    );
  }

  /// Spend per category in `[from, to)`, largest first.
  Stream<List<CategoryTotal>> watchCategoryTotals({
    required DateTime from,
    required DateTime to,
  }) {
    final total = _expenses.amount.sum();
    final query =
        _db.selectOnly(_expenses).join([
            innerJoin(
              _categories,
              _categories.id.equalsExp(_expenses.categoryId),
            ),
          ])
          ..addColumns([
            _categories.id,
            _categories.name,
            _categories.icon,
            total,
          ])
          ..where(
            _expenses.date.isBiggerOrEqualValue(from) &
                _expenses.date.isSmallerThanValue(to),
          )
          ..groupBy([_categories.id])
          ..orderBy([OrderingTerm.desc(total)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          CategoryTotal(
            categoryId: r.read(_categories.id)!,
            name: r.read(_categories.name)!,
            icon: r.read(_categories.icon)!,
            total: r.read(total) ?? 0,
          ),
      ],
    );
  }

  Future<int> addExpense({
    required double amount,
    required String merchant,
    required int categoryId,
    required DateTime date,
    required ExpenseSource source,
    String currency = 'INR',
    String? rawText,
    double? confidence,
  }) => _db
      .into(_expenses)
      .insert(
        ExpensesCompanion.insert(
          amount: amount,
          currency: Value(currency),
          merchant: merchant,
          categoryId: categoryId,
          date: date,
          source: source,
          rawText: Value(rawText),
          confidence: Value(confidence),
        ),
      );

  Future<void> deleteExpense(int id) =>
      (_db.delete(_expenses)..where((e) => e.id.equals(id))).go();

  Future<void> upsertOverride({
    required String merchantNormalized,
    required int categoryId,
  }) => _db
      .into(_overrides)
      .insertOnConflictUpdate(
        MerchantOverridesCompanion.insert(
          merchantNormalized: merchantNormalized,
          categoryId: categoryId,
        ),
      );

  @override
  Future<String?> categoryNameFor(String merchantNormalized) async {
    final query = _db.select(_overrides).join([
      innerJoin(_categories, _categories.id.equalsExp(_overrides.categoryId)),
    ])..where(_overrides.merchantNormalized.equals(merchantNormalized));
    final row = await query.getSingleOrNull();
    return row?.readTable(_categories).name;
  }
}
