import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api/api_client.dart';
import '../../shared/models/models.dart';
import '../auth/auth_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref);
});

class AuthRepository {
  AuthRepository(this._api, this._ref);

  final ApiClient _api;
  final Ref _ref;

  Future<void> loginWithGoogle(String idToken) async {
    final res = await _api.post('/api/auth/google', body: {'id_token': idToken});
    await _applyAuthResponse(res);
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> res) async {
    final data = res['data'];
    if (data is! Map) throw Exception('Unexpected server response');

    final token = data['token'];
    if (token is! String) throw Exception('Missing auth token');

    final user = data['user'];
    String? userId;
    String? email;
    if (user is Map) {
      userId = user['id']?.toString();
      email = user['email']?.toString();
    }

    await _ref.read(authNotifierProvider.notifier).setSession(
          token: token,
          userId: userId,
          email: email,
        );
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _ref.read(authNotifierProvider.notifier).logout();
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(apiClientProvider));
});

class ExpenseRepository {
  ExpenseRepository(this._api);

  final ApiClient _api;

  Future<List<Expense>> list({
    String? from,
    String? to,
    String? category,
    String? type,
    String? search,
  }) async {
    final res = await _api.get('/api/expenses', query: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (search != null) 'search': search,
    });
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> create({
    required String categoryId,
    required double amount,
    required TransactionType type,
    String? note,
    String? merchant,
    required String date,
    String? currency,
  }) async {
    final res = await _api.post('/api/expenses', body: {
      'category_id': categoryId,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      if (note != null) 'note': note,
      if (merchant != null) 'merchant': merchant,
      'date': date,
      if (currency != null) 'currency': currency,
    });
    return Expense.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.post('/api/expenses', body: {
      'action': 'delete',
      'id': id,
    });
  }

  Future<Expense> update({
    required String id,
    String? categoryId,
    double? amount,
    TransactionType? type,
    String? date,
    String? currency,
    String? merchant,
  }) async {
    final res = await _api.post('/api/expenses', body: {
      'action': 'update',
      'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type == TransactionType.income ? 'income' : 'expense',
      if (date != null) 'date': date,
      if (currency != null) 'currency': currency,
      if (merchant != null) 'merchant': merchant,
    });
    return Expense.fromJson(res['data'] as Map<String, dynamic>);
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
});

class CategoryRepository {
  CategoryRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> list() async {
    final res = await _api.get('/api/categories');
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create({required String name, String icon = 'ic:category'}) async {
    final res = await _api.post('/api/categories', body: {
      'name': name,
      'icon': icon,
    });
    return Category.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Category> update({
    required String id,
    String? name,
    String? icon,
  }) async {
    final res = await _api.post('/api/categories', body: {
      'action': 'update',
      'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
    });
    return Category.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.post('/api/categories', body: {
      'action': 'delete',
      'id': id,
    });
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(apiClientProvider));
});

class AnalyticsRepository {
  AnalyticsRepository(this._api);

  final ApiClient _api;

  Future<AnalyticsSummary> summary({String? from, String? to}) async {
    final res = await _api.get('/api/analytics', query: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return AnalyticsSummary.fromJson(res['data'] as Map<String, dynamic>);
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiClientProvider));
});

class BudgetRepository {
  BudgetRepository(this._api);

  final ApiClient _api;

  Future<List<Budget>> list() async {
    final res = await _api.get('/api/budgets');
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Budget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Budget> create({
    required String name,
    required double amount,
    String? categoryId,
    String period = 'monthly',
  }) async {
    final res = await _api.post('/api/budgets', body: {
      'name': name,
      'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      'period': period,
    });
    return Budget.fromJson(res['data'] as Map<String, dynamic>);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<Profile> get() async {
    final res = await _api.get('/api/profile');
    return Profile.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Profile> update({String? currency, String? displayName}) async {
    final res = await _api.patch('/api/profile', body: {
      if (currency != null) 'currency': currency,
      if (displayName != null) 'display_name': displayName,
    });
    return Profile.fromJson(res['data'] as Map<String, dynamic>);
  }
}
