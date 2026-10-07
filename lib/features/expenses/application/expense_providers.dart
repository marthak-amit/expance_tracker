import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../domain/expense_with_category.dart';

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchCategories(),
);

final expensesProvider = StreamProvider<List<ExpenseWithCategory>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchExpenses(),
);
