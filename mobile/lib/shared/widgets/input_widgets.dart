import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/folio_theme.dart';
import 'category_icon.dart';

/// Converts stored amount to a clean keypad string (200.0 → "200").
String amountInputFromDouble(double value) {
  if (value == value.truncateToDouble()) {
    return value.truncate().toString();
  }
  return value.toString();
}

String formatAmountDisplay(String amountStr, String currency) {
  if (amountStr.isEmpty) return '${currency}0.00';
  if (amountStr == '.' || amountStr.endsWith('.')) {
    return '$currency$amountStr';
  }
  final parsed = double.tryParse(amountStr);
  if (parsed == null) return '$currency$amountStr';
  return '$currency${NumberFormat('#,##0.00').format(parsed)}';
}

class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.isExpense,
    required this.onChanged,
  });

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => PremiumTypeToggle(isExpense: isExpense, onChanged: onChanged);
}

class PremiumTypeToggle extends StatelessWidget {
  const PremiumTypeToggle({
    super.key,
    required this.isExpense,
    required this.onChanged,
  });

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: FolioColors.surfaceMuted,
        borderRadius: BorderRadius.circular(FolioRadii.pill),
        border: Border.all(color: FolioColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeChip(
              label: 'expense',
              icon: Icons.arrow_downward_rounded,
              selected: isExpense,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeChip(
              label: 'income',
              icon: Icons.arrow_upward_rounded,
              selected: !isExpense,
              highlight: true,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (highlight ? FolioColors.foreground : FolioColors.foreground)
        : Colors.transparent;
    final fg = selected ? FolioColors.background : FolioColors.foreground;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FolioRadii.pill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: FolioColors.foreground.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(label, style: FolioText.label13.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class MonthDatePicker extends StatelessWidget {
  const MonthDatePicker({
    super.key,
    required this.month,
    required this.selected,
    required this.onMonthChanged,
    required this.onDateChanged,
  });

  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: FolioText.label15.copyWith(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (context, i) {
              final day = DateTime(month.year, month.month, i + 1);
              final isSelected = day.year == selected.year &&
                  day.month == selected.month &&
                  day.day == selected.day;
              final weekday = DateFormat('EEE').format(day).toLowerCase();
              return GestureDetector(
                onTap: () => onDateChanged(day),
                child: Container(
                  width: 52,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? FolioColors.foreground : FolioColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? FolioColors.foreground : FolioColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: FolioText.label16.copyWith(
                          color: isSelected ? FolioColors.background : FolioColors.foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        weekday,
                        style: FolioText.meta12.copyWith(
                          color: isSelected
                              ? FolioColors.background.withValues(alpha: 0.75)
                              : FolioColors.foreground.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
            CategoryIcon(icon: icon, size: 16, color: FolioColors.background),
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
    this.showConfirmButton = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;
  final bool showConfirmButton;

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
        if (showConfirmButton) ...[
          const SizedBox(height: 8),
          _KeyButton(
            label: '✓',
            onTap: onConfirm,
            filled: true,
          ),
        ],
      ],
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.filled ? double.infinity : 72,
          height: 56,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _pressed
                ? (widget.filled
                    ? FolioColors.foreground.withValues(alpha: 0.75)
                    : FolioColors.border)
                : (widget.filled ? FolioColors.foreground : FolioColors.surfaceMuted),
            borderRadius: BorderRadius.circular(widget.filled ? FolioRadii.card : 28),
          ),
          alignment: Alignment.center,
          child: widget.label == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: widget.filled ? FolioColors.background : FolioColors.foreground,
                )
              : Text(
                  widget.label,
                  style: FolioTheme.amountStyle(context, size: widget.filled ? 24 : 22).copyWith(
                    color: widget.filled ? FolioColors.background : FolioColors.foreground,
                  ),
                ),
        ),
      ),
    );
  }
}
