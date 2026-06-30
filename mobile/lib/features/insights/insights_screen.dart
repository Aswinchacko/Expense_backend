import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency.dart';
import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/folio_shell.dart';
import '../data/providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final analytics = ref.watch(analyticsProvider(month));
    final budgets = ref.watch(budgetsProvider);
    final profile = ref.watch(profileProvider);
    final currency = profile.maybeWhen(
      data: (p) => currencySymbol(p.currency),
      orElse: () => r'$',
    );

    return FolioShell(
      currentIndex: 2,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            Text('insights', style: FolioTheme.amountStyle(context, size: 28)),
            const SizedBox(height: 24),
            analytics.when(
              loading: () => const CircularProgressIndicator(color: FolioColors.foreground),
              error: (e, _) => Text('$e'),
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WaveTrendChart(points: summary.trend, height: 160),
                  const SizedBox(height: 32),
                  Text('by category', style: FolioTheme.labelStyle(context, size: 16)),
                  const SizedBox(height: 8),
                  if (summary.byCategory.isEmpty)
                    Text('no expenses this month', style: FolioTheme.metaStyle(context))
                  else
                    ...summary.byCategory.map((c) => CategoryBar(
                          label: c.name,
                          amount: c.total,
                          percent: c.percent,
                          icon: c.icon,
                          currency: currency,
                        )),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('budgets', style: FolioTheme.labelStyle(context, size: 16)),
            const SizedBox(height: 8),
            budgets.when(
              loading: () => const CircularProgressIndicator(color: FolioColors.foreground),
              error: (e, _) => Text('$e'),
              data: (list) {
                if (list.isEmpty) {
                  return Text('no budgets set', style: FolioTheme.metaStyle(context));
                }
                return Column(
                  children: list.map((b) => BudgetBar(
                        name: b.name,
                        spent: b.spent,
                        total: b.amount,
                        percent: b.spentPercent,
                        currency: currency,
                      )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
