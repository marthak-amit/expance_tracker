import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final _monthFmt = DateFormat('MMMM yyyy');
final _dayFmt = DateFormat('d MMM yyyy');

String formatInr(double amount) => _inr.format(amount);
String formatMonth(DateTime d) => _monthFmt.format(d);
String formatDay(DateTime d) => _dayFmt.format(d);
