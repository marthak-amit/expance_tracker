import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'default_categories.dart';
import 'tables.dart';

export 'tables.dart' show ExpenseSource;

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Expenses, MerchantOverrides])
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'expance_tracker'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) {
        b.insertAll(categories, [
          for (final (name, icon) in defaultCategories)
            CategoriesCompanion.insert(name: name, icon: icon),
        ]);
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
