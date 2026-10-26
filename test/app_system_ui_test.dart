import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/window/display_util.dart';
import 'package:kikoenai/core/widgets/layout/app_system_ui.dart';

void main() {
  final calls = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method.startsWith('SystemChrome.setEnabledSystemUI')) {
            calls.add(call);
          }
          return null;
        });
    calls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    TargetPlatform platform = TargetPlatform.iOS,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        builder: (_, child) => AppSystemUi(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Another page')),
                ),
              ),
              child: const Text('Open page'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectStatusBarHidden() {
    expect(calls.last.method, 'SystemChrome.setEnabledSystemUIOverlays');
    expect(calls.last.arguments, ['SystemUiOverlay.bottom']);
  }

  void expectNormalMode() {
    expect(calls.last.method, 'SystemChrome.setEnabledSystemUIMode');
    expect(calls.last.arguments, 'SystemUiMode.edgeToEdge');
  }

  testWidgets('phone rotation hides only status bar across routes', (
    tester,
  ) async {
    await mount(tester);
    expectNormalMode();
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expectStatusBarHidden();
    final rotationCallCount = calls.length;

    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    expect(find.text('Another page'), findsOneWidget);
    expect(calls.length, rotationCallCount);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expectNormalMode();
    expect(tester.takeException(), isNull);
  });

  testWidgets('launching or resuming in landscape hides status bar', (
    tester,
  ) async {
    await mount(tester, size: const Size(844, 390));
    expectStatusBarHidden();
    final initialCalls = calls.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls.length, initialCalls + 1);
    expectStatusBarHidden();
    await tester.pumpWidget(const SizedBox.shrink());
    expectNormalMode();
  });

  testWidgets(
    'video fullscreen takes precedence and restores current rotation',
    (tester) async {
      await mount(tester, size: const Size(844, 390));
      expectStatusBarHidden();

      final systemUi = DisplayUtils.mobileSystemUi;
      addTearDown(systemUi.exitFullscreen);
      await systemUi.enterFullscreen();
      expect(calls.last.arguments, 'SystemUiMode.immersiveSticky');
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(calls.last.arguments, 'SystemUiMode.immersiveSticky');
      await systemUi.exitFullscreen();
      expectNormalMode();

      await systemUi.enterFullscreen();
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(calls.last.arguments, 'SystemUiMode.immersiveSticky');
      await systemUi.exitFullscreen();
      expectStatusBarHidden();
      await tester.pumpWidget(const SizedBox.shrink());
      expectNormalMode();
    },
  );

  for (final scenario in [
    (platform: TargetPlatform.iOS, size: const Size(1024, 768)),
    (platform: TargetPlatform.macOS, size: const Size(844, 390)),
  ]) {
    testWidgets('${scenario.platform} non-phone keeps its system UI', (
      tester,
    ) async {
      await mount(tester, size: scenario.size, platform: scenario.platform);
      tester.view.physicalSize = Size(
        scenario.size.height,
        scenario.size.width,
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });
  }
}
