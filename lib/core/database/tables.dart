import 'package:drift/drift.dart';

/// Where an expense came from. Stored as text so rows stay readable and new
/// values can be appended without a migration.
enum ExpenseSource { manual, receipt, sms }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();

  /// Emoji shown next to the category.
  TextColumn get icon => text()();
}

@TableIndex(name: 'expenses_date', columns: {#date})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get merchant => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => textEnum<ExpenseSource>()();

  /// Full OCR / SMS text the expense was derived from (null for manual).
  TextColumn get rawText => text().nullable()();

  /// Categorizer confidence in [0, 1]; 1.0 when the user picked the category.
  RealColumn get confidence => real().nullable()();
}

/// User corrections. Looked up before any categorizer runs.
class MerchantOverrides extends Table {
  TextColumn get merchantNormalized => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {merchantNormalized};
}
