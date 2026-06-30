import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../shared/models/models.dart';
import 'currency.dart';

class ExportService {
  static Future<void> exportBankStatement({
    required Profile profile,
    required List<Expense> expenses,
    required DateTime month,
  }) async {
    final symbol = currencySymbol(profile.currency);
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final generated = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final income = expenses.where((e) => e.type == TransactionType.income);
    final spending = expenses.where((e) => e.type == TransactionType.expense);
    final incomeTotal = income.fold<double>(0, (s, e) => s + e.amount);
    final expenseTotal = spending.fold<double>(0, (s, e) => s + e.amount);
    final balance = incomeTotal - expenseTotal;

    final byCategory = <String, double>{};
    for (final e in spending) {
      final key = e.category?.name ?? 'Other';
      byCategory[key] = (byCategory[key] ?? 0) + e.amount;
    }
    final topCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text('folio', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('account statement', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(monthLabel, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('generated $generated', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _stat('opening balance', '$symbol${balance.toStringAsFixed(2)}'),
                _stat('money in', '$symbol${incomeTotal.toStringAsFixed(2)}'),
                _stat('money out', '$symbol${expenseTotal.toStringAsFixed(2)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('how you spent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          if (topCategories.isEmpty)
            pw.Text('no spending recorded this month.')
          else
            ...topCategories.take(6).map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(e.key),
                      pw.Text('$symbol${e.value.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
          pw.SizedBox(height: 16),
          pw.Text(
            'tip: keep essentials under 50% of income. trim the top 2 discretionary categories first.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          pw.Text('transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['date', 'description', 'type', 'amount'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: expenses.map((e) {
              final sign = e.type == TransactionType.income ? '+' : '-';
              return [
                e.date,
                e.displayTitle,
                e.type.name,
                '$sign$symbol${e.amount.toStringAsFixed(2)}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            '${profile.displayName ?? profile.email ?? 'Account holder'} · ${profile.email ?? ''}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'folio-statement-$monthLabel.pdf',
    );
  }

  static pw.Widget _stat(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      );
}

const moneyQuotes = [
  'wealth is what you keep, not what you earn.',
  'a budget is telling your money where to go.',
  'small leaks sink great ships — plug them early.',
  'financial freedom is a habit, not a jackpot.',
  'track it daily, stress less monthly.',
  'every rupee has a job. give it one.',
];

String dailyMoneyQuote() => moneyQuotes[DateTime.now().day % moneyQuotes.length];
