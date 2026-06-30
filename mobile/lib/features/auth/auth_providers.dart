import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_service.dart';

const _emailKey = 'folio_user_email';

class AuthState {
  const AuthState({this.token, this.userId, this.email});

  final String? token;
  final String? userId;
  final String? email;

  bool get isAuthenticated => token != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(token: AuthService.instance.token));

  Future<void> loadFromStorage() async {
    await AuthService.instance.loadToken();
    final token = AuthService.instance.token;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (token != state.token || email != state.email) {
      state = AuthState(token: token, email: email);
    }
  }

  Future<void> setSession({required String token, String? userId, String? email}) async {
    await AuthService.instance.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_emailKey, email);
    }
    state = AuthState(token: token, userId: userId, email: email);
  }

  Future<void> logout() async {
    await AuthService.instance.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final authInitProvider = FutureProvider<void>((ref) async {
  await ref.read(authNotifierProvider.notifier).loadFromStorage();
});
