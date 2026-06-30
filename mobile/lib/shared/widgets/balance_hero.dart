import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme/folio_theme.dart';
import '../../features/data/providers.dart';

class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key, required this.amount, this.currency = '\$'});

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        formatCurrency(amount, symbol: currency),
        key: ValueKey(amount),
        style: FolioTheme.amountStyle(context, size: 44),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isIncome = false,
    this.currency = '\$',
  });

  final String icon;
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final prefix = isIncome ? '+' : '-';
    final formatted = NumberFormat('#,##0.00').format(amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FolioTheme.labelStyle(context, size: 15)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: FolioTheme.metaStyle(context, size: 12)),
              ],
            ),
          ),
          Text(
            '$prefix$currency$formatted',
            style: FolioTheme.labelStyle(context, size: 15),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0);
  }
}
