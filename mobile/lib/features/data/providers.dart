import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/models/models.dart';
import '../data/repositories.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryRepositoryProvider).list();
});

final expensesProvider = FutureProvider.family<List<Expense>, DateTime>((ref, month) async {
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 0);
  final fmt = DateFormat('yyyy-MM-dd');
  return ref.watch(expenseRepositoryProvider).list(
        from: fmt.format(from),
        to: fmt.format(to),
      );
});

final analyticsProvider = FutureProvider.family<AnalyticsSummary, DateTime>((ref, month) async {
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 0);
  final fmt = DateFormat('yyyy-MM-dd');
  return ref.watch(analyticsRepositoryProvider).summary(
        from: fmt.format(from),
        to: fmt.format(to),
      );
});

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  return ref.watch(budgetRepositoryProvider).list();
});

final profileProvider = FutureProvider<Profile>((ref) async {
  return ref.watch(profileRepositoryProvider).get();
});

String formatCurrency(double amount, {String symbol = '\$'}) {
  final formatted = NumberFormat('#,##0.00').format(amount.abs());
  if (amount < 0) return '-$symbol$formatted';
  if (amount > 0) return '+$symbol$formatted';
  return '$symbol$formatted';
}
