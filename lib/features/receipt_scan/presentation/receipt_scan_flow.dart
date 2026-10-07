import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/application/expense_actions.dart';
import '../../expenses/presentation/expense_form.dart';
import '../application/receipt_scan_service.dart';

/// Camera/gallery -> OCR -> editable confirm sheet -> save.
Future<void> startReceiptScan(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  ScannedReceipt? scanned;
  try {
    scanned = await _withBusyDialog(
      context,
      () => ref.read(receiptScanServiceProvider).scan(source),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not read receipt: $e')),
    );
    return;
  }
  if (scanned == null || !context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ConfirmSheet(scanned: scanned!),
  );
}

Future<T> _withBusyDialog<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

class _ConfirmSheet extends ConsumerWidget {
  const _ConfirmSheet({required this.scanned});
  final ScannedReceipt scanned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = scanned.parsed;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirm receipt',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (parsed.amount == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Couldn’t find a total — please enter the amount.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          ExpenseForm(
            submitLabel: 'Save expense',
            initialAmount: parsed.amount,
            initialMerchant: parsed.merchant,
            initialDate: parsed.date,
            initialCategory: scanned.category,
            initialConfidence: scanned.confidence,
            onSubmit: (result) async {
              await ref
                  .read(expenseActionsProvider)
                  .save(
                    result,
                    source: ExpenseSource.receipt,
                    rawText: parsed.rawText,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          if (parsed.rawText.trim().isNotEmpty)
            ExpansionTile(
              title: const Text('Recognised text'),
              tilePadding: EdgeInsets.zero,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    parsed.rawText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
