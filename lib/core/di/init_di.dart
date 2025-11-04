import 'package:get_it/get_it.dart';
import 'package:name_app/features/album/data/service/album_repository.dart';
import 'package:name_app/features/tag/data/service/tag_repository.dart';

import '../network/api_client.dart';
import '../../features/user/data/services/user_repository.dart';
import '../../features/user/domain/user_usecases.dart';

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

  /// 注册GetUsersUseCase 实现类
  if (!getIt.isRegistered<GetUsersUseCase>()) {
    getIt.registerFactory<GetUsersUseCase>(
        () => GetUsersUseCase(getIt<UserRepository>()));
  }

  /// 注册TagRepository 实现类
  if (!getIt.isRegistered<TagRepository>()) {
    getIt.registerLazySingleton<TagRepository>(
        () => TagRepositoryImpl(getIt<ApiClient>()));
  }

  /// 注册AlbumRepository 实现类
  if (!getIt.isRegistered<AlbumRepository>()) {
    getIt.registerLazySingleton<AlbumRepository>(
        () => AlbumRepositoryImpl(getIt<ApiClient>()));
  }
}
