import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai/features/auth/page/auth_page.dart';
import 'package:kikoenai/features/auth/provider/auth_provider.dart';
import 'package:kikoenai/features/auth/provider/auth_state.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(currentUser: null, token: null);

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register(String username, String password) async {}
}

void main() {
  Future<void> pumpAuthPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availableSurfacesProvider.overrideWithValue(const {
            AppSurface.loginAction,
            AppSurface.registerAction,
          }),
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          home: const AuthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the responsive login form and keeps validation', (
    tester,
  ) async {
    await pumpAuthPage(tester);

    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('登录你的账户以继续'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('去注册'), findsOneWidget);
    expect(find.byTooltip('显示密码'), findsOneWidget);

    await tester.tap(find.text('登录'));
    await tester.pump();

    expect(find.text('请输入用户名'), findsAtLeastNWidgets(1));
    expect(find.text('请输入密码'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps registration switch and password visibility control', (
    tester,
  ) async {
    await pumpAuthPage(tester);

    await tester.tap(find.text('去注册'));
    await tester.pumpAndSettle();

    expect(find.text('创建账户'), findsOneWidget);
    expect(find.text('填写账户信息完成注册'), findsOneWidget);
    expect(find.text('注册'), findsOneWidget);
    expect(find.text('去登录'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    final passwordField = find.descendant(
      of: find.byType(TextFormField).last,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);

    await tester.tap(find.byTooltip('显示密码'));
    await tester.pump();

    expect(find.byTooltip('隐藏密码'), findsOneWidget);
    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains scrollable without overflow on a compact viewport', (
    tester,
  ) async {
    await pumpAuthPage(tester, size: const Size(320, 568));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pump();

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('去注册'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
