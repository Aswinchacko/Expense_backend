import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';

class AuthState {
  const AuthState({this.token, this.userId, this.email});

  final String? token;
  final String? userId;
  final String? email;

  bool get isAuthenticated => token != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> loadFromStorage() async {
    await AuthService.instance.loadToken();
    final token = AuthService.instance.token;
    state = AuthState(token: token);
  }

  Future<void> setSession({required String token, String? userId, String? email}) async {
    await AuthService.instance.saveToken(token);
    state = AuthState(token: token, userId: userId, email: email);
  }

  Future<void> logout() async {
    await AuthService.instance.clearToken();
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
