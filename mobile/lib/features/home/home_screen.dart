import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/balance_hero.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/folio_shell.dart';
import '../../shared/models/models.dart';
import '../data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final analytics = ref.watch(analyticsProvider(month));
    final expenses = ref.watch(expensesProvider(month));
    final profile = ref.watch(profileProvider);

    final currency = profile.maybeWhen(
      data: (p) => _currencySymbol(p.currency),
      orElse: () => '\$',
    );

    return FolioShell(
      currentIndex: 0,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(analyticsProvider(month));
            ref.invalidate(expensesProvider(month));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showMonthPicker(context, ref, month),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(month),
                          style: FolioTheme.labelStyle(context, size: 15),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              analytics.when(
                loading: () => const Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
                error: (e, _) => Text('Error: $e'),
                data: (summary) => Column(
                  children: [
                    BalanceHero(amount: summary.balance, currency: currency),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'income ${currency}${summary.incomeTotal.toStringAsFixed(0)}',
                          style: FolioTheme.metaStyle(context, size: 12),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'spent ${currency}${summary.expenseTotal.toStringAsFixed(0)}',
                          style: FolioTheme.metaStyle(context, size: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    WaveTrendChart(points: summary.trend),
                    const SizedBox(height: 8),
                    MonthScrubber(
                      selected: month,
                      onSelected: (m) => ref.read(selectedMonthProvider.notifier).state = m,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('today', style: FolioTheme.labelStyle(context, size: 16)),
              const SizedBox(height: 8),
              expenses.when(
                loading: () => const CircularProgressIndicator(color: FolioColors.foreground),
                error: (e, _) => Text('Error: $e'),
                data: (list) {
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final todayExpenses = list.where((e) => e.date == today).toList();

                  if (todayExpenses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('no transactions today', style: FolioTheme.metaStyle(context)),
                    );
                  }

                  return Column(
                    children: todayExpenses.map((e) {
                      return TransactionTile(
                        icon: e.category?.icon ?? '📦',
                        title: e.displayTitle,
                        subtitle: e.displaySubtitle,
                        amount: e.amount,
                        isIncome: e.type == TransactionType.income,
                        currency: currency,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 300,
        child: MonthScrubber(
          selected: current,
          year: current.year,
          onSelected: (m) {
            ref.read(selectedMonthProvider.notifier).state = m;
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  String _currencySymbol(String code) {
    const symbols = {
      'USD': '\$', 'EUR': '€', 'GBP': '£', 'INR': '₹',
      'JPY': '¥', 'CAD': 'C\$', 'AUD': 'A\$',
    };
    return symbols[code] ?? '\$';
  }
}
