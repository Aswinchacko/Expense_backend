import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/folio_theme.dart';
import '../../features/data/providers.dart';
import 'category_icon.dart';

class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key, required this.amount, this.currency = r'$'});

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCurrency(amount, symbol: currency),
      style: FolioText.amount44,
      textAlign: TextAlign.center,
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
    this.currency = r'$',
    this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final prefix = isIncome ? '+' : '-';
    final formatted = NumberFormat('#,##0.00').format(amount);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CategoryIcon(icon: icon, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FolioText.label15),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: FolioText.meta12),
              ],
            ),
          ),
          Text(
            '$prefix$currency$formatted',
            style: FolioText.label15,
          ),
        ],
      ),
      ),
    );
  }
}
