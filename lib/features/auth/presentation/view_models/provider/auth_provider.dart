import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import '../../../../../core/common/shared_preferences_service.dart';
import '../../../../../core/storage/hive_box.dart';
import '../../../../user/data/models/user.dart';
import '../../../data/model/login_params.dart';
import '../../../data/service/auth_repository.dart';
import '../state/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _authRepository;
  late final SharedPreferencesService _service;
  late final HiveStorage _hiveStorage;
  @override
  Future<AuthState> build() async {
    _authRepository = ref.read(authRepositoryProvider);
    _service = ref.read(sharedPreferencesServiceProvider);
    
    _hiveStorage = await HiveStorage.getInstance();
    final userJson = await _hiveStorage.get(BoxNames.user, StorageKeys.currentUser);
    final user = userJson != null
        ? User.fromJson(Map<String, dynamic>.from(userJson))
        : null;
    final res = await _service.fetchToken();
    final token = res.data;
    return AuthState(
      currentUser: user,
      token: token,
      isLoggedIn: token != null,
    );
  }
  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authRepository.login(
        LoginParams(username: username, password: password),
      );

      if (result.data != null) {
        final data = result.data!;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;
        final user = userJson != null ? User.fromJson(userJson) : null;

        // 保存 token
        await _service.saveToken(token);
        if (userJson != null) {
          await _hiveStorage.put(BoxNames.user, StorageKeys.currentUser, userJson);
        }
        state = AsyncValue.data(
          AuthState(
            currentUser: user,
            token: token,
            isLoggedIn: token != null,
          ),
        );

        return true;
      } else {
        state = AsyncValue.data(
          AuthState(error: result.message ?? '登录失败'),
        );
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
      () => AuthNotifier(),
);