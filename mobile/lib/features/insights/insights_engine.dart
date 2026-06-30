import 'package:flutter/material.dart';

import '../../shared/models/models.dart';

class InsightTip {
  const InsightTip({
    required this.icon,
    required this.title,
    required this.body,
    this.tone = InsightTone.neutral,
  });

  final IconData icon;
  final String title;
  final String body;
  final InsightTone tone;
}

enum InsightTone { success, warning, neutral, action }

List<InsightTip> buildInsights({
  required AnalyticsSummary summary,
  required DateTime month,
  required String currency,
}) {
  final tips = <InsightTip>[];
  final now = DateTime.now();
  final isCurrentMonth = month.year == now.year && month.month == now.month;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final daysElapsed = isCurrentMonth ? now.day.clamp(1, daysInMonth) : daysInMonth;
  final dailyBurn = daysElapsed > 0 ? summary.expenseTotal / daysElapsed : 0.0;
  final savingsRate = summary.incomeTotal > 0
      ? ((summary.balance / summary.incomeTotal) * 100).round()
      : null;

  if (summary.incomeTotal == 0 && summary.expenseTotal > 0) {
    tips.add(InsightTip(
      icon: Icons.receipt_long_outlined,
      title: 'Log your income',
      body:
          'You\'ve spent $currency${summary.expenseTotal.toStringAsFixed(0)} but no income is recorded. Add salary or transfers to see your real savings rate.',
      tone: InsightTone.action,
    ));
  }

  if (summary.balance < 0) {
    final gap = summary.expenseTotal - summary.incomeTotal;
    tips.add(InsightTip(
      icon: Icons.trending_down,
      title: 'Spending over income',
      body:
          'You\'re down $currency${gap.toStringAsFixed(0)} this month. Pause non-essentials for a week or move $currency${(gap / 4).ceil()} from your biggest category.',
      tone: InsightTone.warning,
    ));
  } else if (summary.balance > 0 && summary.incomeTotal > 0) {
    tips.add(InsightTip(
      icon: Icons.savings_outlined,
      title: 'You\'re in the green',
      body:
          'Net +$currency${summary.balance.toStringAsFixed(0)} (${savingsRate ?? 0}% saved). Park ${savingsRate != null && savingsRate >= 20 ? 'another' : 'at least'} 20% before discretionary spends.',
      tone: InsightTone.success,
    ));
  }

  if (summary.byCategory.isNotEmpty) {
    final top = summary.byCategory.first;
    if (top.percent >= 35) {
      tips.add(InsightTip(
        icon: Icons.pie_chart_outline,
        title: '${top.name} dominates',
        body:
            '${top.percent}% of spending ($currency${top.total.toStringAsFixed(0)}). Cap it at $currency${(summary.expenseTotal * 0.25).toStringAsFixed(0)} next month — that alone frees up room.',
        tone: InsightTone.warning,
      ));
    } else {
      tips.add(InsightTip(
        icon: Icons.category_outlined,
        title: 'Top category: ${top.name}',
        body:
            '$currency${top.total.toStringAsFixed(0)} (${top.percent}%). Spending is spread — keep ${top.name} under $currency${(top.total * 1.1).toStringAsFixed(0)} to stay balanced.',
        tone: InsightTone.neutral,
      ));
    }
  }

  if (dailyBurn > 0) {
    final projected = dailyBurn * daysInMonth;
    tips.add(InsightTip(
      icon: Icons.local_fire_department_outlined,
      title: 'Daily burn: $currency${dailyBurn.toStringAsFixed(0)}',
      body: isCurrentMonth
          ? 'At this pace you\'ll spend ~$currency${projected.toStringAsFixed(0)} by month end. ${projected > summary.incomeTotal && summary.incomeTotal > 0 ? 'That exceeds income — slow down now.' : 'Track big purchases on weekends when burn usually spikes.'}'
          : 'You averaged $currency${dailyBurn.toStringAsFixed(0)}/day across $daysInMonth days.',
      tone: projected > summary.incomeTotal && summary.incomeTotal > 0
          ? InsightTone.warning
          : InsightTone.neutral,
    ));
  }

  if (summary.expenseTotal == 0 && summary.incomeTotal == 0) {
    tips.add(InsightTip(
      icon: Icons.lightbulb_outline,
      title: 'Start tracking',
      body: 'Add a few expenses and your income. Folio will show where money leaks and what to cut first.',
      tone: InsightTone.action,
    ));
  }

  if (tips.length < 3 && summary.balance >= 0 && summary.expenseTotal > 0) {
    tips.add(InsightTip(
      icon: Icons.rule_outlined,
      title: '50/30/20 rule',
      body:
          'Aim for 50% needs, 30% wants, 20% savings. Your spend is $currency${summary.expenseTotal.toStringAsFixed(0)} — tag categories to see which bucket they fall in.',
      tone: InsightTone.neutral,
    ));
  }

  return tips.take(4).toList();
}
