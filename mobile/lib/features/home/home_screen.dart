import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/balance_hero.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/premium_widgets.dart';
import '../../shared/models/models.dart';
import '../data/providers.dart';
import '../expense/transaction_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final expensesAsync = ref.watch(expensesProvider(month));
    final pending = ref.watch(pendingExpensesProvider);
    final analytics = ref.watch(analyticsProvider(month));
    final profile = ref.watch(profileProvider);
    final currency = ref.watch(currencySymbolProvider);
    final name = profile.maybeWhen(data: (p) => p.firstName, orElse: () => 'there');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesProvider(month));
          ref.invalidate(profileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            FolioGreeting(name: name),
            const SizedBox(height: 20),
            analytics.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
              ),
              error: (e, _) => Text('$e', style: FolioText.meta12),
              data: (summary) => FolioCard(
                child: Column(
                  children: [
                    BalanceHero(amount: summary.balance, currency: currency),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _pill('in', '$currency${summary.incomeTotal.toStringAsFixed(0)}'),
                        const SizedBox(width: 10),
                        _pill('out', '$currency${summary.expenseTotal.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SparklineChart(points: summary.trend, height: 140),
                    const SizedBox(height: 12),
                    MonthScrubber(
                      selected: month,
                      onSelected: (m) => ref.read(selectedMonthProvider.notifier).state = m,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('transactions', style: FolioText.label16),
            const SizedBox(height: 8),
            expensesAsync.when(
              loading: () => _loadingList(ref, pending, analytics, currency),
              error: (e, _) => Text('$e', style: FolioText.meta12),
              data: (list) => _transactionList(context, ref, list, pending, currency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FolioColors.surfaceMuted,
        borderRadius: BorderRadius.circular(FolioRadii.pill),
      ),
      child: Text('$label $value', style: FolioText.meta12),
    );
  }

  Widget _loadingList(WidgetRef ref, List<Expense> pending, AsyncValue analytics, String currency) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayPending = pending.where((e) => e.date == today).toList();
    if (todayPending.isEmpty && !analytics.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
      );
    }
    return Column(
      children: [
        for (final e in todayPending) _tile(null, ref, e, currency),
      ],
    );
  }

  Widget _transactionList(
    BuildContext context,
    WidgetRef ref,
    List<Expense> list,
    List<Expense> pending,
    String currency,
  ) {
    final merged = [...list, ...pending.where((e) => !list.any((x) => x.id == e.id))];
    merged.sort((a, b) => b.date.compareTo(a.date));
    if (merged.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('no transactions this month', style: FolioText.meta12),
      );
    }
    return Column(
      children: [
        for (final e in merged.take(30))
          _tile(context, ref, e, currency),
      ],
    );
  }

  Widget _tile(BuildContext? context, WidgetRef ref, Expense e, String currency) {
    return TransactionTile(
      icon: e.category?.icon ?? 'ic:category',
      title: e.displayTitle,
      subtitle: '${e.date} · ${e.displaySubtitle}',
      amount: e.amount,
      isIncome: e.type == TransactionType.income,
      currency: currency,
      onTap: e.id.startsWith('local-') || context == null
          ? null
          : () => showTransactionSheet(context, ref, e),
    );
  }
}
