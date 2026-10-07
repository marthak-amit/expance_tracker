import 'package:drift/native.dart';
import 'package:expance_tracker/core/database/app_database.dart';
import 'package:expance_tracker/core/database/default_categories.dart';
import 'package:expance_tracker/features/ai/categorizer/keyword_categorizer.dart';
import 'package:expance_tracker/features/ai/categorizer/override_first_categorizer.dart';
import 'package:expance_tracker/features/expenses/data/expense_repository.dart';
import 'package:expance_tracker/features/expenses/domain/month_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ExpenseRepository repo;
  late Map<String, int> ids;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ExpenseRepository(db);
    ids = {for (final c in await db.select(db.categories).get()) c.name: c.id};
  });
  tearDown(() => db.close());

  Future<void> add(
    String merchant,
    double amount,
    DateTime date,
    String category,
  ) => repo.addExpense(
    amount: amount,
    merchant: merchant,
    categoryId: ids[category]!,
    date: date,
    source: ExpenseSource.manual,
  );

  test('default categories are seeded', () {
    expect(ids.keys, containsAll(defaultCategories.map((c) => c.$1)));
  });

  test('expenses come back newest first and group by month', () async {
    await add('A', 100, DateTime(2024, 2, 10), CategoryNames.food);
    await add('B', 50, DateTime(2024, 3, 2), CategoryNames.food);
    await add('C', 25, DateTime(2024, 3, 20), CategoryNames.transport);

    final items = await repo.watchExpenses().first;
    expect(items.map((e) => e.expense.merchant), ['C', 'B', 'A']);

    final groups = groupByMonth(items);
    expect(groups.map((g) => g.month), [DateTime(2024, 3), DateTime(2024, 2)]);
    expect(groups.first.total, 75);
  });

  test(
    'category totals are limited to the month and sorted by spend',
    () async {
      await add('A', 100, DateTime(2024, 2, 28), CategoryNames.food);
      await add('B', 50, DateTime(2024, 3, 1), CategoryNames.food);
      await add('C', 120, DateTime(2024, 3, 31), CategoryNames.transport);
      await add('D', 10, DateTime(2024, 4, 1), CategoryNames.food);

      final totals = await repo
          .watchCategoryTotals(from: DateTime(2024, 3), to: DateTime(2024, 4))
          .first;
      expect(totals.map((t) => (t.name, t.total)), [
        (CategoryNames.transport, 120.0),
        (CategoryNames.food, 50.0),
      ]);
    },
  );

  test(
    'a saved override changes the next classification of that merchant',
    () async {
      final categorizer = OverrideFirstCategorizer(
        delegate: KeywordCategorizer(),
        overrides: repo,
      );
      expect((await categorizer.classify('Swiggy', '')).$1, CategoryNames.food);

      await repo.upsertOverride(
        merchantNormalized: 'swiggy',
        categoryId: ids[CategoryNames.groceries]!,
      );
      expect(await categorizer.classify('Swiggy', ''), (
        CategoryNames.groceries,
        1.0,
      ));

      // Upsert replaces rather than duplicating.
      await repo.upsertOverride(
        merchantNormalized: 'swiggy',
        categoryId: ids[CategoryNames.entertainment]!,
      );
      expect(
        (await categorizer.classify('SWIGGY', '')).$1,
        CategoryNames.entertainment,
      );
    },
  );

  test('deleting removes the expense', () async {
    await add('A', 1, DateTime(2024, 1, 1), CategoryNames.other);
    final id = (await repo.watchExpenses().first).single.expense.id;
    await repo.deleteExpense(id);
    expect(await repo.watchExpenses().first, isEmpty);
  });
}
