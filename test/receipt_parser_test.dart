import 'package:expance_tracker/features/receipt_scan/domain/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed clock so "future date" rejection is deterministic.
  final parser = ReceiptParser(clock: () => DateTime(2024, 6, 1));

  test(
    '1. food delivery bill: Grand Total beats Subtotal, GST and Total Savings',
    () {
      const text = '''
Spice Garden Restaurant
MG Road, Bengaluru
GSTIN: 29ABCDE1234F1Z5
Date: 12 Mar 2024  08:45 PM
Butter Naan x4        120.00
Paneer Tikka          260.00
Subtotal              380.00
CGST 2.5%               9.50
SGST 2.5%               9.50
Total Savings          ₹ 40.00
Grand Total          ₹ 399.00
Thank you, visit again!
''';
      final r = parser.parse(text);
      expect(r.amount, 399.00);
      expect(r.date, DateTime(2024, 3, 12));
      expect(r.merchant, 'Spice Garden Restaurant');
    },
  );

  test(
    '2. supermarket: dd/mm/yyyy, item-count on the Total line, Indian grouping',
    () {
      const text = '''
TAX INVOICE
DMart - Avenue Supermarts Ltd
Bill No: 10234  Date: 05/11/2023 18:22
Rice 5kg              1,150.00
Atta 10kg               640.50
Total Qty: 7
Total 7 items         1,790.50
Cash                  2,000.00
Change                  209.50
''';
      final r = parser.parse(text);
      expect(r.amount, 1790.50);
      expect(r.date, DateTime(2023, 11, 5));
      expect(
        r.merchant,
        'DMart - Avenue Supermarts Ltd',
      ); // "TAX INVOICE" skipped
    },
  );

  test(
    '3. OCR splits label and value onto separate lines; Rs. and /- forms',
    () {
      const text = '''
***
Sharma Electronics
Phone: 98765 43210
Invoice Date 18-01-24
Mobile charger          Rs.1,899/-
Grand Total
Rs. 12,350/-
''';
      final r = parser.parse(text);
      expect(r.amount, 12350);
      expect(r.date, DateTime(2024, 1, 18));
      expect(r.merchant, 'Sharma Electronics');
    },
  );

  test(
    '4. fuel bill: no "Total" line, uses Amount Paid; INR prefix; dotted date',
    () {
      const text = '''
INDIAN OIL - Shree Balaji Fuels
Receipt
Date 18.02.2024 14:35
Product  PETROL
Rate  104.21  Volume 14.39 L
Amount Paid INR 1500.00
''';
      final r = parser.parse(text);
      expect(r.amount, 1500.00);
      expect(r.date, DateTime(2024, 2, 18));
      expect(r.merchant, 'INDIAN OIL - Shree Balaji Fuels');
    },
  );

  test('5. no total keyword anywhere: largest ₹ amount; "Mon d, yyyy" date', () {
    const text = '''
Chai Point
Mar 5, 2024
Masala Chai x2   ₹ 80
Sandwich         ₹ 150
Cash paid        ₹ 500
''';
    // Falls back to the largest currency-marked amount; the user corrects it in
    // the confirm sheet if that is not the real total.
    final r = parser.parse(text);
    expect(r.amount, 500);
    expect(r.date, DateTime(2024, 3, 5));
    expect(r.merchant, 'Chai Point');
  });

  group('edge cases', () {
    test('empty text yields nothing', () {
      final r = parser.parse('');
      expect(r.amount, isNull);
      expect(r.date, isNull);
      expect(r.merchant, isNull);
    });

    test('total with a currency marker wins over trailing GST figure', () {
      expect(parser.parse('Total ₹482.00 (Incl. GST 22.95)').amount, 482.00);
    });

    test('rejects impossible and future dates', () {
      expect(parser.parse('Shop\nDate 31/02/2024').date, isNull);
      expect(parser.parse('Shop\nDate 12/03/2031').date, isNull);
    });

    test('two-digit year and month-name date', () {
      expect(parser.parse('Shop\n7-Apr-24').date, DateTime(2024, 4, 7));
    });
  });
}
