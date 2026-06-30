import 'package:flutter/material.dart';

import '../../core/theme/folio_theme.dart';

class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.isExpense,
    required this.onChanged,
  });

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FolioColors.surfaceMuted,
        borderRadius: BorderRadius.circular(FolioRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillOption(
            label: 'expenses',
            selected: isExpense,
            onTap: () => onChanged(true),
          ),
          _PillOption(
            label: 'income',
            selected: !isExpense,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? FolioColors.foreground : Colors.transparent,
          borderRadius: BorderRadius.circular(FolioRadii.pill),
        ),
        child: Text(
          label,
          style: FolioTheme.labelStyle(context, size: 13).copyWith(
            color: selected ? FolioColors.background : FolioColors.foreground,
          ),
        ),
      ),
    );
  }
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: FolioColors.foreground,
          borderRadius: BorderRadius.circular(FolioRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: FolioTheme.labelStyle(context, size: 13).copyWith(
                color: FolioColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = selected.subtract(Duration(days: selected.weekday - 1));

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, i) {
          final day = start.add(Duration(days: i));
          final isSelected = day.day == selected.day &&
              day.month == selected.month &&
              day.year == selected.year;
          final weekday = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][i];

          return GestureDetector(
            onTap: () => onSelected(day),
            child: Container(
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? FolioColors.foreground : FolioColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: FolioTheme.labelStyle(context, size: 16).copyWith(
                      color: isSelected ? FolioColors.background : FolioColors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    weekday,
                    style: FolioTheme.metaStyle(context, size: 11).copyWith(
                      color: isSelected
                          ? FolioColors.background.withValues(alpha: 0.7)
                          : FolioColors.foreground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FolioKeypad extends StatelessWidget {
  const FolioKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: [
        ...keys.map((row) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                return _KeyButton(
                  label: key,
                  onTap: () {
                    if (key == '⌫') {
                      onBackspace();
                    } else {
                      onDigit(key);
                    }
                  },
                );
              }).toList(),
            )),
        const SizedBox(height: 8),
        _KeyButton(
          label: '✓',
          onTap: onConfirm,
          filled: true,
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: filled ? double.infinity : 72,
        height: 56,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: filled ? FolioColors.foreground : FolioColors.surfaceMuted,
          borderRadius: BorderRadius.circular(filled ? FolioRadii.card : 28),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: FolioTheme.amountStyle(context, size: filled ? 24 : 22).copyWith(
            color: filled ? FolioColors.background : FolioColors.foreground,
          ),
        ),
      ),
    );
  }
}
