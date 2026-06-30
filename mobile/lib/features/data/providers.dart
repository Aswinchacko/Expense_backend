import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/currency.dart';
import '../../shared/models/models.dart';
import '../auth/auth_providers.dart';
import 'analytics_local.dart';
import 'repositories.dart';

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

/// Warm network caches once the shell mounts so tabs don't spin on first open.
void prefetchAppData(WidgetRef ref) {
  ref.read(categoriesProvider);
  ref.read(profileProvider);
  final month = ref.read(selectedMonthProvider);
  ref.read(expensesProvider(month));
  ref.read(budgetsProvider);
}

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

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    _keepAliveWhileAuthed(ref);
    return ref.read(categoryRepositoryProvider).list();
  }

  Future<void> createOptimistic({required String name, required String icon}) async {
    final tempId = 'local-cat-${DateTime.now().microsecondsSinceEpoch}';
    final temp = Category(id: tempId, name: name, icon: icon, userId: 'pending');
    final previous = state;
    state = AsyncData([...state.valueOrNull ?? [], temp]);
    try {
      final created = await ref.read(categoryRepositoryProvider).create(name: name, icon: icon);
      state = AsyncData(
        (state.valueOrNull ?? []).map((c) => c.id == tempId ? created : c).toList(),
      );
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> updateOptimistic({
    required String id,
    required String name,
    required String icon,
  }) async {
    final previous = state;
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((c) => c.id == id ? Category(id: id, name: name, icon: icon, userId: c.userId) : c)
          .toList(),
    );
    try {
      final updated = await ref.read(categoryRepositoryProvider).update(id: id, name: name, icon: icon);
      state = AsyncData(
        (state.valueOrNull ?? []).map((c) => c.id == id ? updated : c).toList(),
      );
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteOptimistic(String id) async {
    final previous = state;
    state = AsyncData((state.valueOrNull ?? []).where((c) => c.id != id).toList());
    try {
      await ref.read(categoryRepositoryProvider).delete(id);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(CategoriesNotifier.new);

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
  final base = ref.watch(expensesProvider(month)).whenData((list) => computeAnalytics(list, month));
  final pending = ref.watch(pendingExpensesProvider);
  if (pending.isEmpty) return base;
  return base.whenData((summary) {
    final monthPending = pending.where((e) => _expenseInMonth(e, month)).toList();
    if (monthPending.isEmpty) return summary;
    return computeAnalytics([
      ...?ref.read(expensesProvider(month)).valueOrNull,
      ...monthPending,
    ], month);
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
