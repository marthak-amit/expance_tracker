import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../application/expense_actions.dart';
import 'expense_form.dart';

class AddExpenseScreen extends ConsumerWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ExpenseForm(
            submitLabel: 'Save',
            onSubmit: (result) async {
              await ref
                  .read(expenseActionsProvider)
                  .save(result, source: ExpenseSource.manual);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}
