import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_player.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('overlay_lyrics_font_');
    Hive.init(hiveDir.path);
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('Android JSON re-encode turns a whole font size into an int', () {
    // Java JSONObject.numberToString strips the trailing ".0" before the
    // message reaches the main isolate, so 18.0 arrives as 18.
    final decoded = jsonDecode(
      '{"action":"${PlayerConstants.updateFontSize}","payload":{"size":18}}',
    );

    expect(decoded['payload']['size'], isA<int>());
    expect(overlayFontSizeFromPayload(decoded['payload']), 18.0);
  });

  test('persists an integer font size from the overlay channel', () async {
    final message = jsonDecode(
      '{"action":"${PlayerConstants.updateFontSize}","payload":{"size":18}}',
    ) as Map;

    expect(
      persistOverlaySettingsCommand(
        AppStorage.settingsBox,
        message['action'] as String,
        message['payload'],
      ),
      isTrue,
    );

    expect(AppStorage.settingsBox.get(StorageKeys.overlayLyricsFontSize), 18.0);
    expect(overlayFontSizeFromPayload({'size': 18.0}), 18.0);
  });

  test('persists integer overlay coordinates from the overlay channel', () {
    final message = jsonDecode(
      '{"action":"${PlayerConstants.savePosition}","payload":{"x":120,"y":40.5}}',
    ) as Map;

    expect(
      persistOverlaySettingsCommand(
        AppStorage.settingsBox,
        message['action'] as String,
        message['payload'],
      ),
      isTrue,
    );

    expect(AppStorage.settingsBox.get(StorageKeys.overlayLyricsPositionX), 120);
    expect(
      AppStorage.settingsBox.get(StorageKeys.overlayLyricsPositionY),
      40.5,
    );
  });

  test('ignores a font-size payload that is not a number', () {
    expect(overlayFontSizeFromPayload({'size': '18'}), isNull);
    expect(overlayFontSizeFromPayload(null), isNull);
    expect(overlayPositionFromPayload({'x': 1}), isNull);
  });
}
