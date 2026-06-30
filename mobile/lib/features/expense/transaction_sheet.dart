import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/folio_messenger.dart';
import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/input_widgets.dart';
import '../data/providers.dart';
import '../data/repositories.dart';

Future<void> showTransactionSheet(BuildContext context, WidgetRef ref, Expense expense) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _TransactionEditor(expense: expense),
    ),
  );
}

class _TransactionEditor extends ConsumerStatefulWidget {
  const _TransactionEditor({required this.expense});

  final Expense expense;

  @override
  ConsumerState<_TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends ConsumerState<_TransactionEditor> {
  late bool _isExpense;
  late String _amountStr;
  late DateTime _pickerMonth;
  late DateTime _selectedDate;
  Category? _category;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.expense.type == TransactionType.expense;
    _amountStr = amountInputFromDouble(widget.expense.amount);
    _selectedDate = DateTime.parse(widget.expense.date);
    _pickerMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _category = widget.expense.category;
  }

  void _onDigit(String digit) {
    setState(() {
      if (_amountStr == '0' && digit != '.') {
        _amountStr = digit;
      } else if (digit == '.' && _amountStr.contains('.')) {
        return;
      } else {
        _amountStr += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountStr.length <= 1) {
        _amountStr = '0';
      } else {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      }
    });
  }

  Future<bool> _confirmFutureDate() async {
    final today = DateTime.now();
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final now = DateTime(today.year, today.month, today.day);
    if (!selected.isAfter(now)) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('future date? really?'),
        content: const Text(
          'you picked a future date. bold strategy.\n\n'
          'are you time-traveling with your money or just procrastinating reality?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('nah, fix it')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('yes, i\'m from the future')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _save() async {
    if (_category == null) return;
    final amount = double.tryParse(_amountStr) ?? 0;
    if (amount <= 0) {
      showFolioSnack('enter an amount', isError: true);
      return;
    }
    if (!await _confirmFutureDate()) return;

    final month = ref.read(selectedMonthProvider);
    try {
      await ref.read(expenseRepositoryProvider).update(
            id: widget.expense.id,
            categoryId: _category!.id,
            amount: amount,
            type: _isExpense ? TransactionType.expense : TransactionType.income,
            date: DateFormat('yyyy-MM-dd').format(_selectedDate),
            merchant: _category!.name,
          );
      ref.invalidate(expensesProvider(month));
      if (mounted) Navigator.pop(context);
      showFolioSnack('transaction updated');
    } catch (e) {
      showFolioSnack('$e', isError: true);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('delete transaction?'),
        content: const Text('this cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('delete')),
        ],
      ),
    );
    if (ok != true) return;

    final month = ref.read(selectedMonthProvider);
    try {
      await ref.read(expenseRepositoryProvider).delete(widget.expense.id);
      ref.invalidate(expensesProvider(month));
      if (mounted) Navigator.pop(context);
      showFolioSnack('transaction deleted');
    } catch (e) {
      showFolioSnack('$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final formatted = formatAmountDisplay(_amountStr, currency);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).padding.bottom + 48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FolioColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit transaction', style: FolioTheme.labelStyle(context, size: 18)),
            const SizedBox(height: 16),
            PremiumTypeToggle(isExpense: _isExpense, onChanged: (v) => setState(() => _isExpense = v)),
            const SizedBox(height: 16),
            MonthDatePicker(
              month: _pickerMonth,
              selected: _selectedDate,
              onMonthChanged: (m) => setState(() {
                _pickerMonth = m;
                _selectedDate = DateTime(m.year, m.month, 1);
              }),
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),
            Text(formatted, style: FolioTheme.amountStyle(context, size: 40), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (_category != null)
              Center(
                child: CategoryPill(
                  icon: _category!.icon,
                  label: _category!.name,
                  onTap: () async {
                    final cat = await context.push<Category>('/pick-category');
                    if (cat != null) setState(() => _category = cat);
                  },
                ),
              ),
            const SizedBox(height: 16),
            FolioKeypad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              onConfirm: _save,
              showConfirmButton: false,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: FolioColors.foreground,
                      foregroundColor: FolioColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FolioRadii.pill),
                      ),
                    ),
                    child: const Icon(Icons.check, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _delete,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FolioRadii.pill),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
