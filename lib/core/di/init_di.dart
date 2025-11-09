import 'package:get_it/get_it.dart';
import 'package:name_app/core/common/shared_preferences_service.dart';
import 'package:name_app/features/album/data/service/album_repository.dart';
import 'package:name_app/features/auth/data/service/auth_repository.dart';
import 'package:name_app/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:name_app/features/tag/data/service/tag_repository.dart';
import 'package:name_app/features/user/presentation/view_models/user_view_model.dart';

import '../utils/network/api_client.dart';
import '../../features/user/data/services/user_repository.dart';

Future<void> initDi() async {
  final getIt = GetIt.I;

  if (!getIt.isRegistered<ApiClient>()) {
    getIt.registerLazySingleton<ApiClient>(() => ApiClient.create());
  }

  /// 注册UserRepository 实现类
  if (!getIt.isRegistered<UserRepository>()) {
    getIt.registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(getIt<ApiClient>()));
  }

  /// 注册TagRepository 实现类
  if (!getIt.isRegistered<TagRepository>()) {
    getIt.registerLazySingleton<TagRepository>(
        () => TagRepositoryImpl(getIt<ApiClient>()));
  }

  /// 注册SharedPreferencesService 实现类
  if (!getIt.isRegistered<SharedPreferencesService>()) {
    getIt.registerLazySingleton<SharedPreferencesService>(
        () => SharedPreferencesService());
  }

  /// 注册AlbumRepository 实现类
  if (!getIt.isRegistered<AlbumRepository>()) {
    getIt.registerLazySingleton<AlbumRepository>(
        () => AlbumRepositoryImpl(getIt<ApiClient>()));
  }
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        getIt<ApiClient>(), getIt<SharedPreferencesService>()));
  }
  if (!getIt.isRegistered<UserViewModel>()) {
    getIt.registerLazySingleton<UserViewModel>(() => UserViewModel());
  }
  if (!getIt.isRegistered<AuthViewModel>()) {
    getIt.registerLazySingleton<AuthViewModel>(() => AuthViewModel());
  }
}
