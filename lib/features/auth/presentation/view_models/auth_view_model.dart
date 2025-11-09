import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:name_app/core/common/shared_preferences_service.dart';
import 'package:name_app/features/auth/data/model/login_params.dart';
import 'package:name_app/features/auth/data/service/auth_repository.dart';
import 'package:name_app/features/user/data/services/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  final SharedPreferencesService _sharedPreferencesService =
      GetIt.I<SharedPreferencesService>();
  final UserRepository _userRepository = GetIt.I<UserRepository>();

  bool _loading = false;
  String? _error;
  bool _isLoggedIn = false; // 新增登录状态字段

  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  AuthViewModel() {
    _checkLoginStatus(); // 启动时自动检查本地 token
  }
  Future<void> clearError() async {
    _error = null;
    notifyListeners();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _sharedPreferencesService.fetchToken();
    _isLoggedIn = token.data != null && token.data!.isNotEmpty;
    notifyListeners(); // 通知 UI 或路由刷新
  }

  Future<void> login(LoginParams loginParams) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authRepository.login(loginParams);
      if (res.isSuccess && res.code == 200) {
        final token = res.data?.token;
        if (token != null && token.isNotEmpty) {
          await _sharedPreferencesService.saveToken(token);
          _isLoggedIn = true; // 登录成功后修改状态
          await _userRepository
              .getUsers()
              .then((res) => _sharedPreferencesService.saveUserInfo(res.data!));
        } else {
          _error = '登录失败,token 为空';
        }
      } else {
        _error = res.message ?? '登录失败';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    final result = await _sharedPreferencesService.removeAll(); // 清除 token
    _isLoggedIn = false;
    notifyListeners(); // 通知 UI 更新登录状态
    return result.isSuccess;
  }

  Future<void> register(Map<String, dynamic> params) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (params['pwd'].toString().length < 6) {
        throw Exception('密码长度至少6位');
      }

      await Future.delayed(const Duration(seconds: 1));
      // 模拟注册成功
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
