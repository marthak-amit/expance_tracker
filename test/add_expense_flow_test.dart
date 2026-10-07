import 'package:drift/native.dart';
import 'package:expance_tracker/core/database/app_database.dart';
import 'package:expance_tracker/core/database/default_categories.dart';
import 'package:expance_tracker/core/providers.dart';
import 'package:expance_tracker/features/expenses/data/expense_repository.dart';
import 'package:expance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'manual add: suggestion, user correction saved as override, list + insights update',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());

      // Drift talks to a real isolate/sqlite, so give it real time between pumps.
      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pump(const Duration(milliseconds: 400));
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const ExpenseApp(),
        ),
      );
      await settle();
      expect(find.textContaining('No expenses yet'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '250',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Merchant'),
        'Swiggy',
      );
      await settle();

      ChoiceChip chip(String name) => tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '🍔 $name').hitTestable(),
      );
      // Keyword categorizer suggested Food for "Swiggy".
      expect(chip(CategoryNames.food).selected, isTrue);

      // User disagrees: pick Groceries.
      await tester.tap(
        find.widgetWithText(ChoiceChip, '🛒 ${CategoryNames.groceries}'),
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await settle();

      // Back on the list: grouped by month, showing the corrected category.
      expect(find.text('Swiggy'), findsOneWidget);
      expect(find.textContaining(CategoryNames.groceries), findsOneWidget);
      expect(find.text('₹250.00'), findsWidgets);

      // The correction was persisted for next time.
      final repo = ExpenseRepository(db);
      expect(
        await tester.runAsync(() => repo.categoryNameFor('swiggy')),
        CategoryNames.groceries,
      );

      // Insights tab shows the month's total in the donut centre and the legend.
      await tester.tap(find.text('Insights').last);
      await settle();
      expect(find.text('₹250.00'), findsWidgets);
      expect(find.textContaining(CategoryNames.groceries), findsOneWidget);

      // Dispose the tree (cancels drift streams), flush the zero-duration timer
      // drift schedules on cancel, then close the database.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(db.close);
    },
  );
}
