import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../../../../core/service/cache/cache_service.dart';
import '../../../../../core/service/site/site_api_provider.dart';
import 'auth_state.dart';

final cacheServiceProvider = Provider<CacheService>(
  (ref) => CacheService.instance,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  CacheService get _cacheService => ref.read(cacheServiceProvider);

  String get _siteId => ref.read(activeSiteIdProvider);

  @override
  Future<AuthState> build() async {
    final siteId = ref.watch(activeSiteIdProvider);
    return _loadInitialState(siteId);
  }

  Future<AuthState> _loadInitialState(String siteId) async {
    try {
      final authSession = _cacheService.getAuthSession(siteId: siteId);
      if (authSession != null && authSession.isSuccess) {
        return AuthState(
          currentUser: authSession.user,
          token: authSession.token,
        );
      }
    } catch (e) {
      await _cacheService.clearAuthSession(siteId: siteId);
    }
    return const AuthState(currentUser: null, token: null);
  }

  /// 登录逻辑：不再手动处理 Loading，遇到错误直接 throw 即可
  Future<void> login(String username, String password) async {
    final siteId = _siteId;
    final api = ref.read(siteApiByIdProvider(siteId));
    if (!api.supports(SiteFeature.login)) {
      throw UnsupportedError('当前站点不支持登录');
    }
    final result = await api.login(
      LoginParams(username: username, password: password),
    );
    final newState = await _handleAuthSuccess(siteId, result);
    _publishIfActive(siteId, newState);
  }

  /// 注册逻辑
  Future<void> register(String username, String password) async {
    final siteId = _siteId;
    final api = ref.read(siteApiByIdProvider(siteId));
    if (!api.supports(SiteFeature.register)) {
      throw UnsupportedError('当前站点不支持注册');
    }
    final request = RegisterRequestModel(name: username, password: password);
    // 保留 recommenderUuid 注入逻辑（新的 AsmrOneSiteApi.register 不再注入）
    final uuid = await _cacheService.getOrGenerateRecommendUuid(siteId: siteId);
    final requestWithUuid = request.copyWith(recommenderUuid: uuid);
    final result = await api.register(requestWithUuid);
    final newState = await _handleAuthSuccess(siteId, result);
    _publishIfActive(siteId, newState);
  }

  Future<AuthState> _handleAuthSuccess(
    String siteId,
    AuthResponse authResponse,
  ) async {
    if (!authResponse.isSuccess ||
        authResponse.user == null ||
        authResponse.token == null) {
      throw const FormatException("服务端返回数据不完整");
    }

    await _cacheService.saveAuthSession(authResponse, siteId: siteId);
    ref.invalidate(siteAuthProvider(siteId));
    return AuthState(currentUser: authResponse.user, token: authResponse.token);
  }

  void _publishIfActive(String siteId, AuthState newState) {
    if (ref.read(activeSiteIdProvider) == siteId) {
      state = AsyncData(newState);
    }
  }

  Future<void> logout() async {
    final siteId = _siteId;
    try {
      await _cacheService.clearAuthSession(siteId: siteId);
    } finally {
      ref.invalidate(siteAuthProvider(siteId));
      _publishIfActive(siteId, const AuthState(currentUser: null, token: null));
    }
  }
}

final siteAuthProvider = Provider.family<AuthState, String>((ref, siteId) {
  final session = ref
      .watch(cacheServiceProvider)
      .getAuthSession(siteId: siteId);
  return AuthState(
    currentUser: session?.isSuccess == true ? session?.user : null,
    token: session?.isSuccess == true ? session?.token : null,
  );
});
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

extension AuthRefX on WidgetRef {
  /// 仅获取登录状态，不关心具体用户信�?
  /// 使用 select 优化性能：只�?isLoggedIn 变化时才会触发重�?
  bool get isLoggedIn => watch(
    authNotifierProvider.select(
      (asyncState) => asyncState.value?.isLoggedIn ?? false,
    ),
  );

  /// 获取当前用户（可能为空）
  User? get currentUser => watch(
    authNotifierProvider.select((asyncState) => asyncState.value?.currentUser),
  );
}
