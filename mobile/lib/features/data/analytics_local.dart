import 'package:intl/intl.dart';

import '../../shared/models/models.dart';

AnalyticsSummary computeAnalytics(List<Expense> expenses, DateTime month) {
  var incomeTotal = 0.0;
  var expenseTotal = 0.0;
  final categoryMap = <String, ({String name, String icon, double total})>{};
  final dailyExpense = <String, double>{};
  final dailyIncome = <String, double>{};

  for (final row in expenses) {
    if (row.type == TransactionType.income) {
      incomeTotal += row.amount;
      dailyIncome[row.date] = (dailyIncome[row.date] ?? 0) + row.amount;
    } else {
      expenseTotal += row.amount;
      final cat = row.category;
      final existing = categoryMap[row.categoryId];
      categoryMap[row.categoryId] = (
        name: cat?.name ?? existing?.name ?? 'Other',
        icon: cat?.icon ?? existing?.icon ?? 'ic:category',
        total: (existing?.total ?? 0) + row.amount,
      );
      dailyExpense[row.date] = (dailyExpense[row.date] ?? 0) + row.amount;
    }
  }

  final byCategory = categoryMap.entries
      .map((e) => CategoryBreakdown(
            categoryId: e.key,
            name: e.value.name,
            icon: e.value.icon,
            total: e.value.total,
            percent: expenseTotal > 0 ? ((e.value.total / expenseTotal) * 100).round() : 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  final fmt = DateFormat('yyyy-MM-dd');
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final trend = <TrendPoint>[];
  final dailySpend = <TrendPoint>[];
  var cumulative = 0.0;

  for (var d = 1; d <= lastDay; d++) {
    final date = fmt.format(DateTime(month.year, month.month, d));
    final spent = dailyExpense[date] ?? 0;
    final earned = dailyIncome[date] ?? 0;
    cumulative += earned - spent;
    trend.add(TrendPoint(date: date, amount: cumulative));
    dailySpend.add(TrendPoint(date: date, amount: spent));
  }

  return AnalyticsSummary(
    balance: incomeTotal - expenseTotal,
    incomeTotal: incomeTotal,
    expenseTotal: expenseTotal,
    byCategory: byCategory,
    trend: trend,
    dailySpend: dailySpend,
  );
}
