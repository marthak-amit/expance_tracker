import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/category_colors.dart';
import '../../../core/formatters.dart';
import '../application/expense_actions.dart';
import '../application/expense_providers.dart';
import '../domain/expense_with_category.dart';
import '../domain/month_grouping.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);

    return expenses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load expenses: $e')),
      data: (items) {
        if (items.isEmpty) return const _EmptyState();
        final groups = groupByMonth(items);
        return ListView(
          // Leave room for the floating buttons.
          padding: const EdgeInsets.only(bottom: 160),
          children: [
            for (final g in groups) ...[
              _MonthHeader(group: g),
              for (final e in g.items) _ExpenseTile(item: e),
            ],
          ],
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.group});
  final MonthGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatMonth(group.month),
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            formatInr(group.total),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({required this.item});
  final ExpenseWithCategory item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = item.expense;
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => ref.read(expenseActionsProvider).delete(e.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor(item.category.id)
              .withValues(alpha: 0.2),
          child: Text(item.category.icon),
        ),
        title: Text(e.merchant, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${item.category.name} · ${formatDay(e.date)}'),
        trailing: Text(
          formatInr(e.amount),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'No expenses yet.\nAdd one manually or scan a receipt.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
