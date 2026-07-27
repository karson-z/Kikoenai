import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../../../../core/service/cache/cache_service.dart';
import '../../../../../core/service/site/site_api_provider.dart';
import 'auth_state.dart';

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService.instance);

class AuthNotifier extends AsyncNotifier<AuthState> {
  AsmrOneSiteApi get _api => ref.read(siteApiProvider);
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
    final result = await _api.login(
      LoginParams(username: username, password: password),
    );
    final newState = await _handleAuthSuccess(result);
    // 成功后，直接更新全局用户状态
    state = AsyncData(newState);
  }

  /// 注册逻辑
  Future<void> register(String username, String password) async {
    final request = RegisterRequestModel(name: username, password: password);
    // 保留 recommenderUuid 注入逻辑（新的 AsmrOneSiteApi.register 不再注入）
    final uuid = await _cacheService.getOrGenerateRecommendUuid();
    final requestWithUuid = request.copyWith(recommenderUuid: uuid);
    final result = await _api.register(requestWithUuid);
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
  /// 仅获取登录状态，不关心具体用户信�?
  /// 使用 select 优化性能：只�?isLoggedIn 变化时才会触发重�?
  bool get isLoggedIn => watch(
    authNotifierProvider.select((asyncState) => asyncState.value?.isLoggedIn ?? false),
  );

  /// 获取当前用户（可能为空）
  User? get currentUser => watch(
    authNotifierProvider.select((asyncState) => asyncState.value?.currentUser),
  );
}
