/// Names double as the contract between categorizers and the database:
/// `ExpenseCategorizer.classify` returns one of these strings.
abstract final class CategoryNames {
  static const food = 'Food & Dining';
  static const groceries = 'Groceries';
  static const transport = 'Transport';
  static const shopping = 'Shopping';
  static const bills = 'Bills & Utilities';
  static const entertainment = 'Entertainment';
  static const health = 'Health';
  static const travel = 'Travel';
  static const education = 'Education';
  static const other = 'Other';
}

/// (name, emoji) pairs seeded when the database is first created.
const defaultCategories = <(String, String)>[
  (CategoryNames.food, '🍔'),
  (CategoryNames.groceries, '🛒'),
  (CategoryNames.transport, '🚕'),
  (CategoryNames.shopping, '🛍️'),
  (CategoryNames.bills, '💡'),
  (CategoryNames.entertainment, '🎬'),
  (CategoryNames.health, '💊'),
  (CategoryNames.travel, '✈️'),
  (CategoryNames.education, '📚'),
  (CategoryNames.other, '🧾'),
];
