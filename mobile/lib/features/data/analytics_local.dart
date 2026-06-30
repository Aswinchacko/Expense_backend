import '../../shared/models/models.dart';

AnalyticsSummary computeAnalytics(List<Expense> expenses) {
  var incomeTotal = 0.0;
  var expenseTotal = 0.0;
  final categoryMap = <String, ({String name, String icon, double total})>{};
  final dailyMap = <String, double>{};

  for (final row in expenses) {
    if (row.type == TransactionType.income) {
      incomeTotal += row.amount;
    } else {
      expenseTotal += row.amount;
      final cat = row.category;
      final existing = categoryMap[row.categoryId];
      categoryMap[row.categoryId] = (
        name: cat?.name ?? existing?.name ?? 'Other',
        icon: cat?.icon ?? existing?.icon ?? '📦',
        total: (existing?.total ?? 0) + row.amount,
      );
      dailyMap[row.date] = (dailyMap[row.date] ?? 0) + row.amount;
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

  final trend = dailyMap.entries
      .map((e) => TrendPoint(date: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return AnalyticsSummary(
    balance: incomeTotal - expenseTotal,
    incomeTotal: incomeTotal,
    expenseTotal: expenseTotal,
    byCategory: byCategory,
    trend: trend,
  );
}
