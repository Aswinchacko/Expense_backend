import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/currency.dart';
import '../../shared/models/models.dart';
import '../auth/auth_providers.dart';
import 'analytics_local.dart';
import 'repositories.dart';

final visitedTabsProvider = StateProvider<Set<int>>((ref) => {0});

void markTabVisited(WidgetRef ref, int index) {
  final current = ref.read(visitedTabsProvider);
  if (!current.contains(index)) {
    ref.read(visitedTabsProvider.notifier).state = {...current, index};
  }
}

bool isTabVisited(WidgetRef ref, int index) {
  return ref.watch(visitedTabsProvider).contains(index);
}

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

void _keepAliveWhileAuthed(Ref ref) {
  final link = ref.keepAlive();
  ref.listen(isAuthenticatedProvider, (prev, next) {
    if (!next) link.close();
  });
}

/// Sync currency from disk — no network wait for UI.
final currencyCodeProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('USD') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currency_code');
    if (code != null) state = code;
  }

  Future<void> set(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
  }
}

final currencySymbolProvider = Provider<String>((ref) {
  return currencySymbol(ref.watch(currencyCodeProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  _keepAliveWhileAuthed(ref);
  return ref.read(categoryRepositoryProvider).list();
});

final expensesProvider = FutureProvider.family<List<Expense>, DateTime>((ref, month) async {
  _keepAliveWhileAuthed(ref);
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 0);
  final fmt = DateFormat('yyyy-MM-dd');
  return ref.read(expenseRepositoryProvider).list(
        from: fmt.format(from),
        to: fmt.format(to),
      );
});

final analyticsProvider = Provider.family<AsyncValue<AnalyticsSummary>, DateTime>((ref, month) {
  final base = ref.watch(expensesProvider(month)).whenData(computeAnalytics);
  final pending = ref.watch(pendingExpensesProvider);
  if (pending.isEmpty) return base;
  return base.whenData((summary) {
    final monthPending = pending.where((e) => _expenseInMonth(e, month)).toList();
    if (monthPending.isEmpty) return summary;
    return computeAnalytics([
      ...?ref.read(expensesProvider(month)).valueOrNull,
      ...monthPending,
    ]);
  });
});

bool _expenseInMonth(Expense e, DateTime month) {
  final parts = e.date.split('-');
  if (parts.length != 3) return false;
  return int.parse(parts[0]) == month.year && int.parse(parts[1]) == month.month;
}

class PendingExpensesNotifier extends StateNotifier<List<Expense>> {
  PendingExpensesNotifier() : super(const []);

  String add(Expense expense) {
    state = [...state, expense];
    return expense.id;
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final pendingExpensesProvider =
    StateNotifierProvider<PendingExpensesNotifier, List<Expense>>((ref) {
  return PendingExpensesNotifier();
});

/// Only fetched when insights tab is opened.
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  _keepAliveWhileAuthed(ref);
  return ref.read(budgetRepositoryProvider).list();
});

final profileProvider = FutureProvider<Profile>((ref) async {
  _keepAliveWhileAuthed(ref);
  final profile = await ref.read(profileRepositoryProvider).get();
  await ref.read(currencyCodeProvider.notifier).set(profile.currency);
  return profile;
});

String formatCurrency(double amount, {String symbol = r'$'}) {
  final formatted = NumberFormat('#,##0.00').format(amount.abs());
  if (amount < 0) return '-$symbol$formatted';
  if (amount > 0) return '+$symbol$formatted';
  return '$symbol$formatted';
}
