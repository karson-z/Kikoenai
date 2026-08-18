import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_manager.dart';

void main() {
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
}
