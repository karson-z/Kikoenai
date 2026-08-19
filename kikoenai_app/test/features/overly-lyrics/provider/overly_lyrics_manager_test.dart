import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_manager.dart';

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

  test('uses the shared 120dp overlay height by default', () async {
    MethodCall? showOverlayCall;
    messenger.setMockMethodCallHandler(controlChannel, (call) async {
      if (call.method == 'checkPermission') return true;
      if (call.method == 'showOverlay') showOverlayCall = call;
      return null;
    });

    final manager = AndroidSubtitleManager(SubtitleEndpoint.main);
    await manager.showOverlay();

    expect(SubtitleManager.defaultOverlayHeight, 120);
    expect(
      showOverlayCall?.arguments,
      containsPair('height', SubtitleManager.defaultOverlayHeight),
    );
  });
}
