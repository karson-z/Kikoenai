import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/common/guest_placeholder_view.dart';

void main() {
  Future<void> pumpPlaceholder(
    WidgetTester tester, {
    VoidCallback? onLoginTap,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: Scaffold(body: GuestPlaceholderView(onLoginTap: onLoginTap)),
      ),
    );
  }

  testWidgets('shows the login action and forwards taps', (tester) async {
    var loginTapped = false;
    await pumpPlaceholder(tester, onLoginTap: () => loginTapped = true);

    expect(find.text('需要登录'), findsOneWidget);
    expect(find.text('请登录账号以查看此内容并同步您的数据'), findsOneWidget);
    expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '立即登录'));
    expect(loginTapped, isTrue);
  });

  testWidgets('hides the action when login is unavailable', (tester) async {
    await pumpPlaceholder(tester);

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('does not overflow on a compact viewport', (tester) async {
    await pumpPlaceholder(
      tester,
      size: const Size(280, 280),
      onLoginTap: () {},
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
