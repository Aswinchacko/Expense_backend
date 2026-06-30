import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../shared/models/models.dart';
import 'currency.dart';

String _cap(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _money(double amount, String symbol) => '$symbol${NumberFormat('#,##0.00').format(amount)}';

class ExportService {
  static Future<void> exportBankStatement({
    required Profile profile,
    required List<Expense> expenses,
    required DateTime month,
  }) async {
    final symbol = currencySymbol(profile.currency);
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final periodStart = DateTime(month.year, month.month, 1);
    final periodEnd = DateTime(month.year, month.month + 1, 0);
    final periodLabel =
        '${DateFormat('MMM d').format(periodStart)} – ${DateFormat('MMM d, yyyy').format(periodEnd)}';
    final generated = DateFormat('MMM d, yyyy').format(DateTime.now());

    final incomeRows = expenses.where((e) => e.type == TransactionType.income).toList();
    final expenseRows = expenses.where((e) => e.type == TransactionType.expense).toList();
    final incomeTotal = incomeRows.fold<double>(0, (s, e) => s + e.amount);
    final expenseTotal = expenseRows.fold<double>(0, (s, e) => s + e.amount);
    final endingBalance = incomeTotal - expenseTotal;

    final byCategory = <String, double>{};
    for (final e in expenseRows) {
      final key = e.category?.name ?? 'Other';
      byCategory[key] = (byCategory[key] ?? 0) + e.amount;
    }
    final topCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
    var running = 0.0;
    final txnRows = <List<String>>[];
    for (final e in sorted) {
      final withdraw = e.type == TransactionType.expense ? _money(e.amount, symbol) : '';
      final deposit = e.type == TransactionType.income ? _money(e.amount, symbol) : '';
      running += e.type == TransactionType.income ? e.amount : -e.amount;
      txnRows.add([
        DateFormat('MM/dd').format(DateTime.parse(e.date)),
        e.displayTitle,
        withdraw,
        deposit,
        _money(running, symbol),
      ]);
    }

    final base = await PdfGoogleFonts.interRegular();
    final bold = await PdfGoogleFonts.interBold();
    final name = profile.displayName ?? profile.firstName;
    final email = profile.email ?? '';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Folio', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Bank Statement', style: pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  if (email.isNotEmpty)
                    pw.Text(email, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text('Currency: ${profile.currency}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Statement date: $generated', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('Account Summary', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _summaryRow('Total money in', _money(incomeTotal, symbol), valueBold: false),
                pw.SizedBox(height: 6),
                _summaryRow('Total money out', _money(expenseTotal, symbol), valueBold: false),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Divider(color: PdfColors.grey300),
                ),
                _summaryRow('Ending balance ($monthLabel)', _money(endingBalance, symbol), valueBold: true),
              ],
            ),
          ),
          if (topCategories.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Spending by category', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...topCategories.take(6).map(
                  (e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(_money(e.value, symbol), style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            _cap('tip: keep essentials under 50% of income. trim your top discretionary categories first.'),
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Transactions', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (txnRows.isEmpty)
            pw.Text('No transactions recorded this period.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Withdraw', 'Deposit', 'Balance'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              data: txnRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'folio-statement-$monthLabel.pdf',
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool valueBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: valueBold ? 12 : 10,
            fontWeight: valueBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

const moneyQuotes = [
  'Wealth is what you keep, not what you earn.',
  'A budget is telling your money where to go.',
  'Small leaks sink great ships — plug them early.',
  'Financial freedom is a habit, not a jackpot.',
  'Track it daily, stress less monthly.',
  'Every rupee has a job. Give it one.',
];

String dailyMoneyQuote() => moneyQuotes[DateTime.now().day % moneyQuotes.length];
