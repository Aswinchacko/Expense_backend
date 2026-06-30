import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/balance_hero.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/premium_widgets.dart';
import '../data/providers.dart';
import 'insights_engine.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final analytics = ref.watch(analyticsProvider(month));
    final budgets = ref.watch(budgetsProvider);
    final currency = ref.watch(currencySymbolProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesProvider(month));
          ref.invalidate(budgetsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            const Text('Insights', style: FolioText.amount28),
            const SizedBox(height: 4),
            Text(
              'Spending breakdown & guidance',
              style: FolioText.meta12,
            ),
            const SizedBox(height: 16),
            MonthScrubber(
              selected: month,
              onSelected: (m) => ref.read(selectedMonthProvider.notifier).state = m,
            ),
            const SizedBox(height: 24),
            analytics.when(
              loading: () => const FolioCard(
                child: SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
                ),
              ),
              error: (e, _) => FolioCard(child: Text('$e', style: FolioText.meta12)),
              data: (summary) => _InsightsBody(
                summary: summary,
                month: month,
                currency: currency,
                budgets: budgets,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({
    required this.summary,
    required this.month,
    required this.currency,
    required this.budgets,
  });

  final AnalyticsSummary summary;
  final DateTime month;
  final String currency;
  final AsyncValue<List<Budget>> budgets;

  @override
  Widget build(BuildContext context) {
    final tips = buildInsights(summary: summary, month: month, currency: currency);
    final savingsRate = summary.incomeTotal > 0
        ? ((summary.balance / summary.incomeTotal) * 100).round()
        : null;
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysElapsed = isCurrent ? now.day : daysInMonth;
    final dailyBurn = daysElapsed > 0 ? summary.expenseTotal / daysElapsed : 0.0;
    final monthLabel = DateFormat('MMMM yyyy').format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FolioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthLabel, style: FolioText.meta12),
              const SizedBox(height: 8),
              BalanceHero(amount: summary.balance, currency: currency),
              const SizedBox(height: 6),
              Center(
                child: _StatusChip(positive: summary.balance >= 0),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: FolioColors.border),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  children: [
                    _MetricCell(
                      label: 'Income',
                      value: '$currency${summary.incomeTotal.toStringAsFixed(0)}',
                    ),
                    const _MetricDivider(),
                    _MetricCell(
                      label: 'Spent',
                      value: '$currency${summary.expenseTotal.toStringAsFixed(0)}',
                    ),
                    const _MetricDivider(),
                    _MetricCell(
                      label: savingsRate != null ? 'Saved' : 'Net',
                      value: savingsRate != null ? '$savingsRate%' : '${summary.balance >= 0 ? '+' : ''}$currency${summary.balance.abs().toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ChartFrame(
                child: SparklineChart(
                  points: summary.trend,
                  height: 100,
                  label: 'Running balance',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Avg $currency${dailyBurn.toStringAsFixed(0)}/day', style: FolioText.meta12),
                  Text(
                    '$daysElapsed of $daysInMonth days',
                    style: FolioText.meta12,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel(title: 'Daily spending', subtitle: 'Expense per day this month'),
        const SizedBox(height: 10),
        FolioCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: _ChartFrame(
            child: DailySpendChart(points: summary.dailySpend, height: 88),
          ),
        ),
        if (summary.byCategory.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionLabel(title: 'Categories', subtitle: 'Where your money went'),
          const SizedBox(height: 10),
          FolioCard(
            child: Column(
              children: [
                CategoryDonutChart(categories: summary.byCategory, size: 140),
                const SizedBox(height: 20),
                for (var i = 0; i < summary.byCategory.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: FolioColors.border),
                  _CategoryRow(
                    category: summary.byCategory[i],
                    currency: currency,
                    rank: i + 1,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionLabel(title: 'Guidance', subtitle: 'Personalised for this month'),
          const SizedBox(height: 10),
          for (final tip in tips) _GuidanceCard(tip: tip),
        ],
        const SizedBox(height: 24),
        const _SectionLabel(title: 'Budgets', subtitle: 'Limits vs actual spend'),
        const SizedBox(height: 10),
        budgets.when(
          loading: () => const FolioCard(
            child: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
            ),
          ),
          error: (e, _) => FolioCard(child: Text('$e', style: FolioText.meta12)),
          data: (list) {
            if (list.isEmpty) {
              return FolioCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: FolioColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.pie_chart_outline,
                        size: 22,
                        color: FolioColors.foreground.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No budgets set. Add limits in Settings to track overspending.',
                        style: FolioText.label14.copyWith(
                          color: FolioColors.foreground.withValues(alpha: 0.65),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return FolioCard(
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: FolioColors.border),
                    BudgetBar(
                      name: list[i].name,
                      spent: list[i].spent,
                      total: list[i].amount,
                      percent: list[i].spentPercent,
                      currency: currency,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: FolioText.label16.copyWith(fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: FolioText.meta12),
        ],
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: FolioText.meta12),
          const SizedBox(height: 6),
          Text(
            value,
            style: FolioText.label15.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(width: 1, thickness: 1, color: FolioColors.border);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.positive});

  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: FolioColors.surfaceMuted,
        borderRadius: BorderRadius.circular(FolioRadii.pill),
        border: Border.all(color: FolioColors.border),
      ),
      child: Text(
        positive ? 'On track this month' : 'Spending over income',
        style: FolioText.label13.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: FolioColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FolioColors.border),
      ),
      child: child,
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.currency,
    required this.rank,
  });

  final CategoryBreakdown category;
  final String currency;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$rank', style: FolioText.meta12),
          ),
          CategoryIcon(icon: category.icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category.name, style: FolioText.label14)),
                    Text(
                      '$currency${category.total.toStringAsFixed(0)}',
                      style: FolioText.label14.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: category.percent / 100,
                    minHeight: 4,
                    backgroundColor: FolioColors.barTrack,
                    color: FolioColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${category.percent}%', style: FolioText.meta12),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.tip});

  final InsightTip tip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FolioCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FolioColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FolioColors.border),
              ),
              child: Icon(tip.icon, size: 20, color: FolioColors.foreground),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: FolioText.label15.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.body,
                    style: FolioText.label14.copyWith(
                      color: FolioColors.foreground.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
