import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/service/cache/cache_service.dart';
import '../../../../user/data/models/user.dart';
import '../../../data/model/auth_response.dart';
import '../../../data/model/login_params.dart';
import '../../../data/model/register_model.dart';
import '../../../data/service/auth_repository.dart';
import '../state/auth_state.dart';

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService.instance);

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  CacheService get _cacheService => ref.read(cacheServiceProvider);

  @override
  Future<AuthState> build() async {
    return _loadInitialState();
  }

  Future<AuthState> _loadInitialState() async {
    try {
      final authSession = _cacheService.getAuthSession();
      if (authSession != null && authSession.isSuccess) {
        return AuthState(
          currentUser: authSession.user,
          token: authSession.token,
        );
      }
    } catch (e) {
      await _cacheService.clearAuthSession();
    }
    return const AuthState(currentUser: null, token: null);
  }

  /// 登录逻辑：不再手动处理 Loading，遇到错误直接 throw 即可
  Future<void> login(String username, String password) async {
    final result = await _authRepository.login(
      LoginParams(username: username, password: password),
    );
    final newState = await _handleAuthSuccess(result);
    // 成功后，直接更新全局用户状态
    state = AsyncData(newState);
  }

  /// 注册逻辑
  Future<void> register(String username, String password) async {
    final request = RegisterRequestModel(name: username, password: password);
    final result = await _authRepository.register(request);
    final newState = await _handleAuthSuccess(result);
    state = AsyncData(newState);
  }

  Future<AuthState> _handleAuthSuccess(AuthResponse authResponse) async {
    if (!authResponse.isSuccess || authResponse.user == null || authResponse.token == null) {
      throw const FormatException("服务端返回数据不完整");
    }

    await _cacheService.saveAuthSession(authResponse);
    return AuthState(currentUser: authResponse.user, token: authResponse.token);
  }

  Future<void> logout() async {
    try {
      await _cacheService.clearAuthSession();
    } finally {
      state = const AsyncValue.data(AuthState(currentUser: null, token: null));
    }
  }
}
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
      () => AuthNotifier(),
);

extension AuthRefX on WidgetRef {
  /// 仅获取登录状态，不关心具体用户信息
  /// 使用 select 优化性能：只有 isLoggedIn 变化时才会触发重绘
  bool get isLoggedIn => watch(
    authNotifierProvider.select((asyncState) => asyncState.value?.isLoggedIn ?? false),
  );

  /// 获取当前用户（可能为空）
  User? get currentUser => watch(
    authNotifierProvider.select((asyncState) => asyncState.value?.currentUser),
  );
}
