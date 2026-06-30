import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/premium_widgets.dart';
import '../data/providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isTabVisited(ref, 2)) {
      return const SafeArea(child: SizedBox.expand());
    }

    final month = ref.watch(selectedMonthProvider);
    final analytics = ref.watch(analyticsProvider(month));
    final budgets = ref.watch(budgetsProvider);
    final currency = ref.watch(currencySymbolProvider);

    return SafeArea(
      child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            Text('insights', style: FolioTheme.amountStyle(context, size: 28)),
            Text('where your money actually goes', style: FolioText.meta12),
            const SizedBox(height: 20),
            analytics.when(
              loading: () => const FolioCard(
                child: SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
                ),
              ),
              error: (e, _) => Text('$e', style: FolioText.meta12),
              data: (summary) => FolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('cash flow', style: FolioText.label16),
                        Text(
                          '${summary.balance >= 0 ? '+' : ''}$currency${summary.balance.toStringAsFixed(0)}',
                          style: FolioText.label15.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SparklineChart(points: summary.trend, height: 160),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            analytics.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (summary) => FolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('by category', style: FolioText.label16),
                    const SizedBox(height: 12),
                    if (summary.byCategory.isEmpty)
                      const Text('no expenses this month', style: FolioText.meta12)
                    else
                      for (final c in summary.byCategory)
                        CategoryBar(
                          label: c.name,
                          amount: c.total,
                          percent: c.percent,
                          icon: c.icon,
                          currency: currency,
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('budgets', style: FolioText.label16),
            const SizedBox(height: 8),
            budgets.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
              ),
              error: (e, _) => Text('$e', style: FolioText.meta12),
              data: (list) {
                if (list.isEmpty) {
                  return const Text('no budgets set', style: FolioText.meta12);
                }
                return Column(
                  children: [
                    for (final b in list)
                      BudgetBar(
                        name: b.name,
                        spent: b.spent,
                        total: b.amount,
                        percent: b.spentPercent,
                        currency: currency,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
  }
}
