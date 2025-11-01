import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:name_app/features/user/presentation/pages/user_page.dart';
import 'package:name_app/features/user/presentation/view_models/user_view_model.dart';
import 'package:name_app/features/user/domain/user_usecases.dart';
import 'package:name_app/core/domain/result.dart';
import 'package:name_app/features/user/data/models/user_model.dart';
import 'package:name_app/features/user/data/services/user_repository.dart';
import 'package:name_app/core/domain/errors.dart';

class _DummyRepo implements UserRepository {
  @override
  Future<Result<List<UserModel>>> getUsers({int? start, int? limit}) async => Result.success([]);
}

class FakeGetUsersUseCaseSuccess extends GetUsersUseCase {
  FakeGetUsersUseCaseSuccess() : super(_DummyRepo());
  @override
  Future<Result<List<UserModel>>> call({int? start, int? limit}) async {
    return Result.success([
      const UserModel(id: 1, name: 'Alice', email: 'alice@example.com'),
      const UserModel(id: 2, name: 'Bob', email: 'bob@example.com'),
    ]);
  }
}

class FakeGetUsersUseCaseFailure extends GetUsersUseCase {
  FakeGetUsersUseCaseFailure() : super(_DummyRepo());
  @override
  Future<Result<List<UserModel>>> call({int? start, int? limit}) async {
    return Result.failure(const NetworkFailure('网络异常，请检查连接'));
  }
}

Widget _wrapWithProviders(UserViewModel vm) {
  return MultiProvider(
    providers: [ChangeNotifierProvider<UserViewModel>.value(value: vm)],
    child: const MaterialApp(home: UserPage()),
  );
}

void main() {
  testWidgets('UserPage shows users on success', (tester) async {
    final vm = UserViewModel(useCase: FakeGetUsersUseCaseSuccess());
    await tester.pumpWidget(_wrapWithProviders(vm));

    expect(find.text('加载用户'), findsOneWidget);
    await tester.tap(find.text('加载用户'));
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('UserPage shows error on failure', (tester) async {
    final vm = UserViewModel(useCase: FakeGetUsersUseCaseFailure());
    await tester.pumpWidget(_wrapWithProviders(vm));

    await tester.tap(find.text('加载用户'));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing); // ensure not using SnackBar
    expect(find.textContaining('网络异常'), findsOneWidget);
  });
}