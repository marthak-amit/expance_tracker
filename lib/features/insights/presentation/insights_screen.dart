import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../application/insights_providers.dart';
import 'category_pie_chart.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final totals = ref.watch(categoryTotalsProvider);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  ref.read(selectedMonthProvider.notifier).shift(-1),
            ),
            Text(
              formatMonth(month),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: isCurrentMonth
                  ? null
                  : () => ref.read(selectedMonthProvider.notifier).shift(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        totals.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load insights: $e'),
          data: (rows) => rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text('No expenses this month.')),
                )
              : CategoryPieChart(totals: rows),
        ),
      ],
    );
  }
}
