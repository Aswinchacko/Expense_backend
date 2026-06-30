import 'package:flutter/material.dart';

import '../../core/theme/folio_theme.dart';

class FolioCard extends StatelessWidget {
  const FolioCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: FolioColors.background,
        borderRadius: BorderRadius.circular(FolioRadii.card),
        border: Border.all(color: FolioColors.border),
        boxShadow: [
          BoxShadow(
            color: FolioColors.foreground.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FolioGreeting extends StatelessWidget {
  const FolioGreeting({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hey $name', style: FolioText.amount28),
        const SizedBox(height: 4),
        Text('here\'s your money snapshot', style: FolioText.meta12),
      ],
    );
  }
}

class FolioQuoteCard extends StatelessWidget {
  const FolioQuoteCard({super.key, required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return FolioCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(quote, style: FolioText.label14)),
        ],
      ),
    );
  }
}

class FolioProfileHeader extends StatelessWidget {
  const FolioProfileHeader({
    super.key,
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: FolioColors.foreground,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(initial, style: FolioText.amount28.copyWith(color: FolioColors.background)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: FolioText.label16.copyWith(fontWeight: FontWeight.w700)),
              Text(email, style: FolioText.meta12),
            ],
          ),
        ),
      ],
    );
  }
}
