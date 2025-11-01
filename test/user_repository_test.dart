import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:name_app/features/user/data/services/user_repository.dart';
import 'package:name_app/core/domain/result.dart';
import 'package:name_app/core/domain/errors.dart';
import 'package:name_app/features/user/data/models/user_model.dart';
import 'package:name_app/core/network/api_client.dart';

class FakeApiClientSuccess extends ApiClient {
  FakeApiClientSuccess() : super(Dio());
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      data: [
        {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
        {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
      ],
      statusCode: 200,
    );
  }
}

class FakeApiClientBadJson extends ApiClient {
  FakeApiClientBadJson() : super(Dio());
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      data: [
        {'id': 'oops', 'name': 123, 'email': null},
      ],
      statusCode: 200,
    );
  }
}

void main() {
  group('UserRepository', () {
    test('returns users on success', () async {
      final repo = UserRepositoryImpl(FakeApiClientSuccess());
      final Result<List<UserModel>> res = await repo.getUsers();
      expect(res.isSuccess, true);
      expect(res.data, isNotNull);
      expect(res.data!.length, 2);
      expect(res.data!.first.name, 'Alice');
    });

    test('maps parse error to ParseFailure', () async {
      final repo = UserRepositoryImpl(FakeApiClientBadJson());
      final res = await repo.getUsers();
      expect(res.isSuccess, false);
      expect(res.error, isA<ParseFailure>());
    });
  });
}