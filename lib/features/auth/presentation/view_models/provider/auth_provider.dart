import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/service/cache/cache_service.dart';
import '../../../../user/data/models/user.dart';
import '../../../data/model/login_params.dart';
import '../../../data/model/register_model.dart';
import '../../../data/service/auth_repository.dart';
import '../state/auth_state.dart';
import '../../../data/model/auth_response.dart'; // 导入之前定义的 AuthResponse

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _authRepository;
  late final CacheService _cacheService;

  @override
  Future<AuthState> build() async {
    _authRepository = ref.read(authRepositoryProvider);
    // 获取单例实例
    _cacheService = CacheService.instance;

    return _loadInitialState();
  }

  /// 初始化逻辑：直接从 CacheService 获取完整的会话信息
  Future<AuthState> _loadInitialState() async {
    try {
      final authSession = await _cacheService.getAuthSession();

      // 验证数据完整性
      if (authSession != null && authSession.isSuccess) {
        return AuthState(
          currentUser: authSession.user,
          token: authSession.token,
        );
      }
    } catch (e) {
      // 如果解析出错（比如数据结构变更），安全起见清除缓存
      await _cacheService.clearAuthSession();
    }

    // 默认未登录
    return const AuthState(currentUser: null, token: null);
  }

  /// 登录方法
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _authRepository.login(
        LoginParams(username: username, password: password),
      );
      return _handleAuthSuccess(result);
    });
  }

  /// 注册方法
  Future<void> register(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final request = RegisterRequestModel(
        name: username,
        password: password,
      );
      final result = await _authRepository.register(request);
      return _handleAuthSuccess(result);
    });
  }

  /// 统一处理认证成功逻辑
  Future<AuthState> _handleAuthSuccess(dynamic result) async {
    if (result.data != null) {
      final data = result.data!;

      final authResponse = AuthResponse(
        user: data['user'] != null ? User.fromJson(data['user']) : null,
        token: data['token'] as String?,
      );

      // 2. 校验关键数据
      if (!authResponse.isSuccess) {
        throw Exception("服务端返回数据不完整");
      }

      // 3. 调用 CacheService 一次性存储 (User + Token)
      await _cacheService.saveAuthSession(authResponse);

      // 4. 更新内存状态
      return AuthState(
        currentUser: authResponse.user,
        token: authResponse.token,
      );
    } else {
      // 处理业务错误
      throw Exception(result.message ?? '操作失败');
    }
  }

  /// 登出方法
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      // 调用 CacheService 清除数据
      await _cacheService.clearAuthSession();

      // 重置状态
      state = const AsyncValue.data(AuthState(currentUser: null, token: null));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
      () => AuthNotifier(),
);