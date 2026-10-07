import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../features/ai/categorizer/expense_categorizer.dart';
import '../features/ai/categorizer/keyword_categorizer.dart';
import '../features/ai/categorizer/override_first_categorizer.dart';
import '../features/expenses/data/expense_repository.dart';
import '../features/receipt_scan/data/ocr_service.dart';
import '../features/receipt_scan/domain/receipt_parser.dart';
import 'database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(appDatabaseProvider)),
);

/// The categorizer the app uses. Swap `KeywordCategorizer` for the TFLite one
/// here in phase 2; overrides keep winning either way.
final categorizerProvider = Provider<ExpenseCategorizer>(
  (ref) => OverrideFirstCategorizer(
    delegate: KeywordCategorizer(),
    overrides: ref.watch(expenseRepositoryProvider),
  ),
);

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = MlKitOcrService();
  ref.onDispose(service.dispose);
  return service;
});

final receiptParserProvider = Provider<ReceiptParser>((ref) => ReceiptParser());

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
