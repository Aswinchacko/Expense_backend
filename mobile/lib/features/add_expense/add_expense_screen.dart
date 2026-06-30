import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/folio_messenger.dart';
import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/input_widgets.dart';
import '../data/providers.dart';
import '../data/repositories.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  bool _isExpense = true;
  late DateTime _pickerMonth;
  DateTime _selectedDate = DateTime.now();
  String _amountStr = '0';
  Category? _category;

  double get _amount => double.tryParse(_amountStr) ?? 0;

  @override
  void initState() {
    super.initState();
    _pickerMonth = DateTime(_selectedDate.year, _selectedDate.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cached = ref.read(categoriesProvider).valueOrNull;
      if (cached != null && cached.isNotEmpty) {
        setState(() => _category = cached.first);
        return;
      }
      ref.read(categoriesProvider.future).then((cats) {
        if (mounted && cats.isNotEmpty && _category == null) {
          setState(() => _category = cats.first);
        }
      });
    });
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
    if (_category == null || _amount <= 0) {
      showFolioSnack('pick a category and amount', isError: true);
      return;
    }
    if (!await _confirmFutureDate()) return;

    final category = _category!;
    final amount = _amount;
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyCode = ref.read(currencyCodeProvider);
    final month = ref.read(selectedMonthProvider);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final type = _isExpense ? TransactionType.expense : TransactionType.income;
    final formatted = NumberFormat('#,##0.00').format(amount);
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';

    ref.read(pendingExpensesProvider.notifier).add(Expense(
          id: tempId,
          categoryId: category.id,
          amount: amount,
          currency: currencyCode,
          type: type,
          date: date,
          merchant: category.name,
          category: category,
        ));

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    context.pop();

    final verb = _isExpense ? 'spent' : 'added';
    showFolioSnack('$verb $currencySymbol$formatted · ${category.name}');

    ref.read(expenseRepositoryProvider).create(
      categoryId: category.id,
      amount: amount,
      type: type,
      date: date,
      merchant: category.name,
      currency: currencyCode,
    ).then((_) {
      ref.read(pendingExpensesProvider.notifier).remove(tempId);
      ref.invalidate(expensesProvider(month));
    }).catchError((_) {
      ref.read(pendingExpensesProvider.notifier).remove(tempId);
      showFolioSnack('save failed — try again', isError: true);
    });
  }

  Future<void> _pickCategory() async {
    final cat = await context.push<Category>('/pick-category');
    if (cat != null) setState(() => _category = cat);
  }

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##0.00').format(_amount);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              PremiumTypeToggle(isExpense: _isExpense, onChanged: (v) => setState(() => _isExpense = v)),
              const SizedBox(height: 20),
              MonthDatePicker(
                month: _pickerMonth,
                selected: _selectedDate,
                onMonthChanged: (m) => setState(() {
                  _pickerMonth = m;
                  _selectedDate = DateTime(m.year, m.month, 1);
                }),
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 28),
              Text('$currency$formatted', style: FolioTheme.amountStyle(context, size: 48)),
              const SizedBox(height: 16),
              if (_category != null)
                CategoryPill(icon: _category!.icon, label: _category!.name, onTap: _pickCategory)
              else
                TextButton(onPressed: _pickCategory, child: const Text('select category')),
              const Spacer(),
              FolioKeypad(onDigit: _onDigit, onBackspace: _onBackspace, onConfirm: _save),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
