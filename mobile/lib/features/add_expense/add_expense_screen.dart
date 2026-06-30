import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  DateTime _selectedDate = DateTime.now();
  String _amountStr = '0';
  Category? _category;
  bool _saving = false;

  double get _amount => double.tryParse(_amountStr) ?? 0;

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

  Future<void> _save() async {
    if (_category == null || _amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category and enter an amount')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(expenseRepositoryProvider).create(
            categoryId: _category!.id,
            amount: _amount,
            type: _isExpense ? TransactionType.expense : TransactionType.income,
            date: DateFormat('yyyy-MM-dd').format(_selectedDate),
            merchant: _category!.name,
          );

      ref.invalidate(expensesProvider(ref.read(selectedMonthProvider)));
      ref.invalidate(analyticsProvider(ref.read(selectedMonthProvider)));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCategory() async {
    final cat = await context.push<Category>('/categories', extra: true);
    if (cat != null) setState(() => _category = cat);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cats = await ref.read(categoriesProvider.future);
      if (cats.isNotEmpty && _category == null) {
        setState(() => _category = cats.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,##0.00').format(_amount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Center(child: PillToggle(isExpense: _isExpense, onChanged: (v) => setState(() => _isExpense = v))),
              const SizedBox(height: 24),
              DateStrip(
                selected: _selectedDate,
                onSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 32),
              Text('\$$formatted', style: FolioTheme.amountStyle(context, size: 48)),
              const SizedBox(height: 16),
              if (_category != null)
                CategoryPill(
                  icon: _category!.icon,
                  label: _category!.name,
                  onTap: _pickCategory,
                )
              else
                TextButton(onPressed: _pickCategory, child: const Text('select category')),
              const Spacer(),
              FolioKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onConfirm: _saving ? () {} : _save,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
