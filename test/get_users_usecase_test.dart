import 'package:flutter_test/flutter_test.dart';
import 'package:name_app/features/user/domain/user_usecases.dart';
import 'package:name_app/features/user/data/services/user_repository.dart';
import 'package:name_app/core/domain/result.dart';
import 'package:name_app/features/user/data/models/user_model.dart';
import 'package:name_app/core/domain/errors.dart';

class FakeRepoSuccess implements UserRepository {
  @override
  Future<Result<List<UserModel>>> getUsers({int? start, int? limit}) async {
    return Result.success([
      const UserModel(id: 1, name: 'Alice', email: 'alice@example.com'),
    ]);
  }
}

class FakeRepoFailure implements UserRepository {
  @override
  Future<Result<List<UserModel>>> getUsers({int? start, int? limit}) async {
    return Result.failure(const NetworkFailure('no network'));
  }
}

void main() {
  group('GetUsersUseCase', () {
    test('returns success from repository', () async {
      final usecase = GetUsersUseCase(FakeRepoSuccess());
      final res = await usecase.call();
      expect(res.isSuccess, true);
      expect(res.data, isNotNull);
      expect(res.data!.first.name, 'Alice');
    });

    test('returns failure from repository', () async {
      final usecase = GetUsersUseCase(FakeRepoFailure());
      final res = await usecase.call();
      expect(res.isSuccess, false);
      expect(res.error, isA<NetworkFailure>());
    });
  });
}