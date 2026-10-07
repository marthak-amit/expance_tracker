import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/category_colors.dart';
import '../../../core/formatters.dart';
import '../../expenses/domain/expense_with_category.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grand = totals.fold(0.0, (s, t) => s + t.total);

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 70,
                  sections: [
                    for (final t in totals)
                      PieChartSectionData(
                        value: t.total,
                        color: categoryColor(t.categoryId),
                        radius: 38,
                        // Tiny slices would be unreadable; the legend has them.
                        showTitle: t.total / grand >= 0.06,
                        title: '${(t.total / grand * 100).round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: theme.textTheme.labelMedium),
                  Text(
                    formatInr(grand),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final t in totals)
          ListTile(
            dense: true,
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: categoryColor(t.categoryId),
                shape: BoxShape.circle,
              ),
            ),
            title: Text('${t.icon} ${t.name}'),
            trailing: Text(
              formatInr(t.total),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
