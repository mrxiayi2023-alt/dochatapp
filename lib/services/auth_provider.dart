// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栖熙启梦网络科技有限公司
// 开发完成日期：2026年6月8日
// 文件说明：认证状态管理Provider（集成腾讯IM登录）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
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
        // Try to re-login to Tencent IM
        if (user != null && user['id'] != null) {
          _loginIM(user['id'] as String, '');
        }
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
      final userSig = data['user_sig'] as String? ?? '';

      await ApiService.instance.saveToken(token);

      // Login to Tencent IM
      if (user != null && user['id'] != null) {
        await _loginIM(user['id'] as String, userSig);
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return null;
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
      final userSig = data['user_sig'] as String? ?? '';

      await ApiService.instance.saveToken(token);

      // Login to Tencent IM
      if (user != null && user['id'] != null) {
        await _loginIM(user['id'] as String, userSig);
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Logout — clear token, logout IM, reset state.
  Future<void> logout() async {
    try {
      await TencentImSDKPlugin.v2TIMManager.logout();
    } catch (_) {
      // IM logout failure is non-critical
    }
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

  /// Login to Tencent IM with userID and userSig.
  Future<void> _loginIM(String userID, String userSig) async {
    if (userSig.isEmpty) return;
    try {
      await TencentImSDKPlugin.v2TIMManager.login(
        userID: userID,
        userSig: userSig,
      );
    } catch (_) {
      // IM login failure is non-critical; app still works
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
