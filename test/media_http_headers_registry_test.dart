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
}
