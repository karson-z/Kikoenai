import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/player/media_http_headers_registry.dart';

void main() {
  test('resolves headers from the latest matching resolver', () {
    final registry = MediaHttpHeadersRegistry();
    final unregisterFirst = registry.register((_) => const {'X-First': '1'});
    final unregisterSecond = registry.register((_) => const {'X-Second': '2'});

    expect(
      registry.resolve(url: 'https://example.test/audio.mp3', extras: const {}),
      const {'X-Second': '2'},
    );

    unregisterSecond();
    expect(
      registry.resolve(url: 'https://example.test/audio.mp3', extras: const {}),
      const {'X-First': '1'},
    );

    unregisterFirst();
    expect(
      registry.resolve(url: 'https://example.test/audio.mp3', extras: const {}),
      isEmpty,
    );
  });

  test(
    'publishes scoped header changes without exposing credentials',
    () async {
      final registry = MediaHttpHeadersRegistry();
      final eventFuture = registry.changes.first;

      registry.notifyChanged(source: 'cloudDrive', siteId: 'webdav');

      final event = await eventFuture;
      expect(event.source, 'cloudDrive');
      expect(event.siteId, 'webdav');
      expect(
        event.matches(const {'source': 'cloudDrive', 'siteId': 'webdav'}),
        isTrue,
      );
      expect(
        event.matches(const {'source': 'cloudDrive', 'siteId': 'other'}),
        isFalse,
      );
      expect(event.matches(const {'source': 'asmrServer'}), isFalse);
    },
  );
}
