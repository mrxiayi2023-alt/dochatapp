import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------------
// Auth State
// ---------------------------------------------------------------------------

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Check if a token is already stored (app startup).
  Future<void> checkAuth() async {
    final api = ApiService.instance;
    await api.loadToken();
    if (api.token != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        token: api.token,
      );
      // Try to load user profile silently
      try {
        final user = await api.getProfile();
        state = state.copyWith(user: user);
      } catch (_) {
        // Token might be expired; continue with just the token
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with phone + password.
  Future<String?> login(String phone, String password) async {
    try {
      final data = await ApiService.instance.login(
        phone: phone,
        password: password,
      );
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>?;
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return null; // no error
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Register a new user.
  Future<String?> register(String phone, String password, String code) async {
    try {
      final data = await ApiService.instance.register(
        phone: phone,
        password: password,
        code: code,
      );
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>?;
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return null; // no error
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Logout — clear token and reset state.
  Future<void> logout() async {
    await ApiService.instance.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Refresh user profile from the server.
  Future<void> refreshProfile() async {
    try {
      final user = await ApiService.instance.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {
      // Silently fail; cached data is fine
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
