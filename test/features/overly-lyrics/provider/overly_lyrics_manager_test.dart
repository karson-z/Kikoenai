import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_manager.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const controlChannel = MethodChannel('x-slayer/overlay_channel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(controlChannel, null);
  });

  group('AndroidSubtitleManager direction guards', () {
    test('main endpoint rejects overlay-to-main messages', () async {
      final manager = AndroidSubtitleManager(SubtitleEndpoint.main);

      await expectLater(manager.sendToMain('test'), throwsA(isA<StateError>()));
    });

    test('overlay endpoint rejects main-to-overlay messages', () async {
      final manager = AndroidSubtitleManager(SubtitleEndpoint.overlay);

      await expectLater(
        manager.sendToOverlay('test'),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('uses a safe no-op manager outside Android', () async {
    final manager = SubtitleManager(SubtitleEndpoint.main);

    expect(manager, isA<NoopSubtitleManager>());
    await manager.init();
    await manager.showOverlay();
    await manager.sendToOverlay('test');
    await manager.hideOverlay();
    expect(await manager.getOverlayPosition(), Offset.zero);
  }, skip: Platform.isAndroid);

  test('keeps the subtitle manager provider readable outside Android', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(overlayLyricsSupportedProvider), isFalse);
    expect(container.read(subtitleManagerProvider), isA<NoopSubtitleManager>());
  }, skip: Platform.isAndroid);

  test('keeps the 190dp window on older Android versions', () async {
    MethodCall? showOverlayCall;
    messenger.setMockMethodCallHandler(controlChannel, (call) async {
      if (call.method == 'checkPermission') return true;
      if (call.method == 'showOverlay') showOverlayCall = call;
      return null;
    });

    final manager = AndroidSubtitleManager(SubtitleEndpoint.main);
    await manager.showOverlay();

    expect(SubtitleManager.defaultOverlayHeight, 190);
    expect(
      showOverlayCall?.arguments,
      containsPair('height', SubtitleManager.defaultOverlayHeight),
    );
  });

  test(
    'reserves settings space with stable position coordinates on Android 13+',
    () async {
      MethodCall? showOverlayCall;
      messenger.setMockMethodCallHandler(controlChannel, (call) async {
        if (call.method == 'checkPermission' ||
            call.method == 'supportsPartialTouchRegion') {
          return true;
        }
        if (call.method == 'showOverlay') showOverlayCall = call;
        return null;
      });

      await AndroidSubtitleManager(
        SubtitleEndpoint.main,
      ).showOverlay(posX: 10, posY: 75, isLocked: true);
      final args = showOverlayCall!.arguments as Map;
      expect(args['height'], 250);
      expect(args['touchableHeight'], 190);
      expect(args['positionAnchorHeight'], 190);
      expect(args['startPosition'], {'x': 10, 'y': 75});
      expect(args['flag'], 'clickThrough');
      expect(args['enableDrag'], isTrue);
    },
  );
}
