import '../../../core/database/app_database.dart';

class ExpenseWithCategory {
  const ExpenseWithCategory(this.expense, this.category);
  final Expense expense;
  final Category category;
}

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.total,
  });
  final int categoryId;
  final String name;
  final String icon;
  final double total;
}
