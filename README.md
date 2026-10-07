# Expense Tracker

On-device expense tracker for Flutter. No backend: data lives in SQLite (drift),
receipts are read with ML Kit OCR, and categorisation runs locally.

## Status

**Phase 1 (done)**
- drift schema: `expenses`, `categories`, `merchant_overrides`
- Manual add, list grouped by month, per-category pie chart (fl_chart)
- Receipt scan: image_picker -> ML Kit OCR -> `ReceiptParser` -> editable confirm sheet
- `ExpenseCategorizer` interface, `KeywordCategorizer` (Indian merchant map),
  `OverrideFirstCategorizer` (checks `merchant_overrides` first). Changing the
  suggested category on save writes an override for that merchant.

**Phase 2 (stubs only, throw `UnimplementedError`)**
- `TfliteCategorizer` (`assets/categorizer.tflite` + `vocab.txt`)
- `LlmService.parseQuery` -> `QueryIntent` (strict JSON validation is implemented),
  `ModelDownloadManager` (Wi-Fi only, progress), `IntentQueryRunner`.
  The LLM only produces an intent; totals always come from a drift query.

## Layout

```
lib/
  core/                 database (drift), providers, formatters
  features/
    expenses/           data / domain / application / presentation
    receipt_scan/       OCR service, ReceiptParser, scan flow + confirm sheet
    insights/           month selector + category pie chart
    ai/
      categorizer/      interface, keyword, override-first, tflite stub
      llm/              LlmService, QueryIntent, download manager (stubs)
```

## Develop

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after schema changes
flutter analyze && flutter test
flutter run
```

`lib/core/database/app_database.g.dart` is generated but committed so a fresh
checkout runs without a codegen step.

Platform minimums: Android `minSdk 24`, iOS 16.0 (flutter_gemma / ML Kit).
`analyzer` is pinned below 14.5.0 because build_runner 2.16.1 does not compile
against it; see the comment in `pubspec.yaml`.
