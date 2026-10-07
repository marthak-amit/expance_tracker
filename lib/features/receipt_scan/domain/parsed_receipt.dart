class ParsedReceipt {
  const ParsedReceipt({
    required this.rawText,
    this.amount,
    this.date,
    this.merchant,
  });

  final String rawText;
  final double? amount;
  final DateTime? date;
  final String? merchant;
}
