import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/default_categories.dart';
import '../../../core/formatters.dart';
import '../../../core/providers.dart';
import '../application/expense_actions.dart';
import '../application/expense_providers.dart';

/// Amount / merchant / date / category form shared by the manual add screen and
/// the receipt confirm sheet.
///
/// Typing a merchant asks the categorizer for a suggestion until the user picks
/// a category themselves. Picking a category that differs from the suggestion
/// is reported as `categoryCorrected` so the caller can persist an override.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initialAmount,
    this.initialMerchant,
    this.initialDate,
    this.initialCategory,
    this.initialConfidence = 0,
  });

  final String submitLabel;
  final Future<void> Function(ExpenseFormResult result) onSubmit;
  final double? initialAmount;
  final String? initialMerchant;
  final DateTime? initialDate;

  /// Suggested category name (from the categorizer), if already known.
  final String? initialCategory;
  final double initialConfidence;

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _merchant;
  late DateTime _date;

  late String _selected;
  late String _suggested;
  late double _suggestedConfidence;
  bool _touched = false;
  bool _saving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.initialAmount == null ? '' : _plain(widget.initialAmount!),
    );
    _merchant = TextEditingController(text: widget.initialMerchant ?? '');
    _date = widget.initialDate ?? DateTime.now();
    _selected = _suggested = widget.initialCategory ?? CategoryNames.other;
    _suggestedConfidence = widget.initialConfidence;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _onMerchantChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _suggestCategory);
  }

  Future<void> _suggestCategory() async {
    if (_touched || _merchant.text.trim().isEmpty) return;
    final (category, confidence) = await ref
        .read(categorizerProvider)
        .classify(_merchant.text, '');
    if (!mounted || _touched) return;
    setState(() {
      _selected = _suggested = category;
      _suggestedConfidence = confidence;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(List<Category> categories) async {
    if (!_formKey.currentState!.validate()) return;
    final category = categories.firstWhere((c) => c.name == _selected);
    final corrected = _selected != _suggested;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        ExpenseFormResult(
          amount: double.parse(_amount.text.replaceAll(',', '')),
          merchant: _merchant.text.trim(),
          date: _date,
          category: category,
          confidence: corrected ? 1.0 : _suggestedConfidence,
          categoryCorrected: corrected,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load categories: $e')),
      data: (cats) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amount,
              autofocus: widget.initialAmount == null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', ''));
                return (n == null || n <= 0)
                    ? 'Enter an amount greater than 0'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _merchant,
              textCapitalization: TextCapitalization.words,
              onChanged: _onMerchantChanged,
              decoration: const InputDecoration(
                labelText: 'Merchant',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a merchant' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatDay(_date)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    label: Text('${c.icon} ${c.name}'),
                    selected: c.name == _selected,
                    onSelected: (_) => setState(() {
                      _touched = true;
                      _selected = c.name;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _submit(cats),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
