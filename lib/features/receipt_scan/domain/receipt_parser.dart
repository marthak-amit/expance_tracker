import 'parsed_receipt.dart';

/// Extracts total amount, date and merchant from OCR text of an Indian receipt.
///
/// Pure Dart, no I/O. Best-effort: every field may come back null, and the
/// confirm sheet lets the user fix whatever was missed or misread.
class ReceiptParser {
  ReceiptParser({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  ParsedReceipt parse(String text) {
    final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).toList();
    return ParsedReceipt(
      rawText: text,
      amount: _extractAmount(lines),
      date: _extractDate(text),
      merchant: _extractMerchant(lines),
    );
  }

  // ---------------------------------------------------------------- amount

  /// A number, optionally preceded by ₹ / Rs / Rs. / INR. Handles Indian digit
  /// grouping (1,23,456.00).
  static final _amountToken = RegExp(
    r'(?:(₹|\brs\b\.?|\binr\b)\s*:?\s*)?'
    r'(?<![\d,])(\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)(?!\d)',
    caseSensitive: false,
  );

  static final _grandTotal = RegExp(
    r'\bgrand\s*-?\s*total\b',
    caseSensitive: false,
  );
  static final _payable = RegExp(
    r'\b(?:amount|amt)\s*(?:payable|due|paid)\b'
    r'|\bnet\s*(?:payable|total|amount)\b'
    r'|\bto\s*pay\b'
    r'|\b(?:bill|invoice)\s*(?:amount|total)\b'
    r'|\btotal\s*(?:amount|amt|payable|due|bill|value)\b',
    caseSensitive: false,
  );
  static final _plainTotal = RegExp(r'\btotal\b', caseSensitive: false);

  /// Phrases containing "total" that are not the payable amount. Stripped from
  /// the line before ranking, so "Total Qty 3  Total 450.00" still ranks.
  static final _notATotal = RegExp(
    r'\bsub\s*-?\s*total\b'
    r'|\btotal\s*(?:tax|gst|cgst|sgst|igst|cess|discount|saving|savings|items?|qty|quantity|taxable|no)\b',
    caseSensitive: false,
  );

  /// 0 = grand total, 1 = explicit payable/amount-due wording, 2 = bare
  /// "Total". Null when the line is not a total line.
  int? _labelRank(String line) {
    final cleaned = line.replaceAll(_notATotal, ' ');
    if (_grandTotal.hasMatch(cleaned)) return 0;
    if (_payable.hasMatch(cleaned)) return 1;
    if (_plainTotal.hasMatch(cleaned)) return 2;
    return null;
  }

  List<_Amount> _amountsIn(String line) => [
    for (final m in _amountToken.allMatches(line))
      if (_toAmount(m.group(2)!) case final v?)
        _Amount(v, hasCurrency: m.group(1) != null),
  ];

  double? _toAmount(String raw) {
    final v = double.tryParse(raw.replaceAll(',', ''));
    return (v != null && v > 0 && v < 10000000) ? v : null;
  }

  /// Prefer the first currency-marked number ("Total ₹482.00 (incl. GST 22.95)"),
  /// otherwise the last number on the line ("Total 3 items 450.00").
  double? _amountFromLine(String line) {
    final amounts = _amountsIn(line);
    if (amounts.isEmpty) return null;
    return amounts
        .firstWhere((a) => a.hasCurrency, orElse: () => amounts.last)
        .value;
  }

  /// True for lines that hold only a number, e.g. "Rs. 2,350/-" - used when OCR
  /// splits "Grand Total" and its value onto separate lines.
  bool _isValueOnly(String line) =>
      _amountsIn(line).isNotEmpty &&
      line
          .replaceAll(_amountToken, '')
          .replaceAll(RegExp(r'[\s:/\-.*|=]|only', caseSensitive: false), '')
          .isEmpty;

  double? _extractAmount(List<String> lines) {
    int? bestRank;
    var bestIndex = -1;
    double? best;

    for (var i = 0; i < lines.length; i++) {
      final rank = _labelRank(lines[i]);
      if (rank == null) continue;

      var value = _amountFromLine(lines[i]);
      if (value == null) {
        final next = lines.skip(i + 1).where((l) => l.isNotEmpty).take(1);
        if (next.isNotEmpty && _isValueOnly(next.first)) {
          value = _amountFromLine(next.first);
        }
      }
      if (value == null) continue;

      // Lowest rank wins; among equals the last one (totals sit at the bottom).
      if (bestRank == null ||
          rank < bestRank ||
          (rank == bestRank && i > bestIndex)) {
        bestRank = rank;
        bestIndex = i;
        best = value;
      }
    }
    if (best != null) return best;

    // No usable total line: largest currency-marked amount, then largest
    // two-decimal amount that is not part of a date.
    double? largest(Iterable<_Amount> amounts) => amounts.isEmpty
        ? null
        : amounts.map((a) => a.value).reduce((a, b) => a > b ? a : b);

    final marked = largest(
      lines.expand(_amountsIn).where((a) => a.hasCurrency),
    );
    if (marked != null) return marked;

    final twoDecimals = RegExp(r'(?<![\d.])\d+\.\d{2}(?!\d)');
    return largest(
      lines
          .where((l) => !_looksLikeDate(l))
          .expand((l) => twoDecimals.allMatches(l))
          .map((m) => _toAmount(m.group(0)!))
          .nonNulls
          .map((v) => _Amount(v, hasCurrency: false)),
    );
  }

  // ------------------------------------------------------------------ date

  static final _numericDate = RegExp(
    r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)',
  );
  static final _isoDate = RegExp(
    r'(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)',
  );
  static final _dayMonthName = RegExp(
    r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)?[\s\-/.,]*([A-Za-z]{3,9})\.?[\s\-/.,]*(\d{4}|\d{2})(?!\d)',
  );
  static final _monthNameDay = RegExp(
    r'\b([A-Za-z]{3,9})\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})(?!\d)',
  );

  static const _months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];

  bool _looksLikeDate(String line) =>
      _numericDate.hasMatch(line) ||
      _isoDate.hasMatch(line) ||
      _dayMonthName
          .allMatches(line)
          .any((m) => _monthNumber(m.group(2)!) != null);

  int? _monthNumber(String word) {
    final w = word.toLowerCase();
    if (w.length < 3) return null;
    final i = _months.indexWhere((m) => m.startsWith(w));
    return i == -1 ? null : i + 1;
  }

  int _fullYear(String y) => y.length == 2 ? 2000 + int.parse(y) : int.parse(y);

  /// Builds a real calendar date or null (rejects 31 Feb, years before 2000 and
  /// anything more than a day in the future, which is almost always an OCR slip).
  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 2000) {
      return null;
    }
    final d = DateTime(year, month, day);
    if (d.month != month || d.day != day) return null;
    if (d.isAfter(_clock().add(const Duration(days: 1)))) return null;
    return d;
  }

  /// The earliest valid date in the text. Numeric dates are day-first (Indian
  /// convention); if that is impossible (e.g. 03/25/2024) month-first is tried.
  DateTime? _extractDate(String text) {
    final found = <(int, DateTime)>[];

    for (final m in _numericDate.allMatches(text)) {
      final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      final y = _fullYear(m.group(3)!);
      final d = _validDate(y, b, a) ?? _validDate(y, a, b);
      if (d != null) found.add((m.start, d));
    }
    for (final m in _isoDate.allMatches(text)) {
      final d = _validDate(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
      if (d != null) found.add((m.start, d));
    }
    for (final m in _dayMonthName.allMatches(text)) {
      final month = _monthNumber(m.group(2)!);
      if (month == null) continue;
      final d = _validDate(
        _fullYear(m.group(3)!),
        month,
        int.parse(m.group(1)!),
      );
      if (d != null) found.add((m.start, d));
    }
    for (final m in _monthNameDay.allMatches(text)) {
      final month = _monthNumber(m.group(1)!);
      if (month == null) continue;
      final d = _validDate(
        int.parse(m.group(3)!),
        month,
        int.parse(m.group(2)!),
      );
      if (d != null) found.add((m.start, d));
    }

    if (found.isEmpty) return null;
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return found.first.$2;
  }

  // -------------------------------------------------------------- merchant

  /// Generic headings printed above the merchant name.
  static final _genericHeader = RegExp(
    r'^(?:tax\s*invoice|retail\s*invoice|gst\s*invoice|invoice|cash\s*(?:memo|bill)|'
    r'bill|receipt|welcome.*|thank\s*you.*|original|duplicate|customer\s*copy)\W*$',
    caseSensitive: false,
  );

  /// First non-empty line, skipping lines with no letters ("-----", phone
  /// numbers) and generic headings like "TAX INVOICE".
  String? _extractMerchant(List<String> lines) {
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (RegExp(r'[A-Za-z]').allMatches(line).length < 2) continue;
      if (_genericHeader.hasMatch(line)) continue;
      final cleaned = line
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9.)]+$'), '');
      if (cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }
}

class _Amount {
  const _Amount(this.value, {required this.hasCurrency});
  final double value;
  final bool hasCurrency;
}
