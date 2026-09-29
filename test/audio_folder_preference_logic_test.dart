import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/file/audio_folder_preference.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai_core/core/model/local_media/file_node.dart';

AudioFolderPreference _preference({
  List<String> formats = AudioFolderPreference.defaultFormats,
  List<AudioEffectPreference> effects = AudioFolderPreference.defaultEffects,
}) {
  return AudioFolderPreference(formats: formats, effects: effects);
}

NodeFolder? _pick(List<String> paths, AudioFolderPreference preference) {
  final index = _index(paths);
  return pickPreferredAudioFolder(
    rootFolders: index.rootNode.foldersList,
    childrenOf: (folder) => folder == null
        ? index.rootNode.foldersList
        : index.rootNode.lookup(folder, stopAtRootPath: 'work')?.foldersList ??
              const [],
    preference: preference,
  );
}

FileNodeLibraryIndex _index(List<String> paths) {
  return FileNodeLibraryIndex(
    rootPath: 'work',
    flatNodes: [
      for (final path in paths)
        FileNode(
          type: NodeType.audio,
          title: path.split('/').last,
          path: path,
          folderPath: NodeFolder(path).parent?.normalized ?? 'work',
        ),
    ],
  );
}

void main() {
  group('folder identity', () {
    test('reads format, alias, bitrate, and fullwidth names', () {
      expect(readFolderAudioIdentity('mp3').format, 'mp3');
      expect(readFolderAudioIdentity('MP3').format, 'mp3');
      expect(readFolderAudioIdentity('ＭＰ３').format, 'mp3');
      expect(readFolderAudioIdentity('320mp3').format, 'mp3');
      expect(readFolderAudioIdentity('320kbps mp3').format, 'mp3');
      expect(readFolderAudioIdentity('24bit wav').format, 'wav');
      expect(readFolderAudioIdentity('wave').format, 'wav');
      expect(readFolderAudioIdentity('alac').format, 'm4a');
      expect(readFolderAudioIdentity('vorbis').format, 'ogg');
      expect(readFolderAudioIdentity('flac（96kHz）').format, 'flac');
    });

    test('does not treat an unrelated name as a format', () {
      for (final name in ['本体', '特典', 'waveform', 'flag', '24bit', '320kbps']) {
        expect(readFolderAudioIdentity(name).format, isNull, reason: name);
      }
      expect(readFolderAudioIdentity('m4a').format, 'm4a');
      expect(readFolderAudioIdentity('opus').format, 'opus');
    });

    test('splits effect marks from the format', () {
      final without = readFolderAudioIdentity('mp3（SEなし）');
      expect(without.format, 'mp3');
      expect(without.effect, AudioEffectPreference.without);

      final withEffect = readFolderAudioIdentity('mp3_se');
      expect(withEffect.format, 'mp3');
      expect(withEffect.effect, AudioEffectPreference.withEffect);

      final effectOnly = readFolderAudioIdentity('効果音あり');
      expect(effectOnly.format, isNull);
      expect(effectOnly.effect, AudioEffectPreference.withEffect);

      final cancelled = readFolderAudioIdentity('seなし_seあり');
      expect(cancelled.effect, isNull);
      expect(readFolderAudioIdentity('sample').effect, isNull);
    });
  });

  group('preferred folder', () {
    test('follows the format order and keeps the plain folder', () {
      final selected = _pick([
        'work/wav/a.wav',
        'work/flac/a.flac',
        'work/mp3/a.mp3',
      ], _preference());
      expect(selected?.name, 'mp3');
    });

    test('falls through when the first format is missing', () {
      final selected = _pick([
        'work/flac/a.flac',
        'work/wav/a.wav',
      ], _preference());
      expect(selected?.name, 'wav');
    });

    test('uses the effect order inside the winning format', () {
      final paths = ['work/mp3_se/a.mp3', 'work/mp3/a.mp3', 'work/wav/a.wav'];

      expect(_pick(paths, _preference())?.name, 'mp3');
      expect(
        _pick(
          paths,
          _preference(
            effects: [
              AudioEffectPreference.withEffect,
              AudioEffectPreference.without,
            ],
          ),
        )?.name,
        'mp3_se',
      );
    });

    test(
      'stays on the preferred format when only its effect variant exists',
      () {
        final selected = _pick([
          'work/mp3_se/a.mp3',
          'work/wav（SEなし）/a.wav',
        ], _preference());
        expect(selected?.name, 'mp3_se');
      },
    );

    test('enters a format nested under an effect folder', () {
      final paths = ['work/SEあり/mp3/a.mp3', 'work/SEなし/mp3/a.mp3'];
      expect(_pick(paths, _preference())?.normalized, 'work/SEなし/mp3');
      expect(
        _pick(
          paths,
          _preference(
            effects: [
              AudioEffectPreference.withEffect,
              AudioEffectPreference.without,
            ],
          ),
        )?.normalized,
        'work/SEあり/mp3',
      );
    });

    test('enters an effect folder nested under a format', () {
      final selected = _pick(
        ['work/mp3/SEなし/a.mp3', 'work/mp3/SEあり/a.mp3'],
        _preference(
          effects: [
            AudioEffectPreference.withEffect,
            AudioEffectPreference.without,
          ],
        ),
      );
      expect(selected?.normalized, 'work/mp3/SEあり');
    });

    test('stays at the root when no folder names a format', () {
      expect(
        _pick([
          'work/本体/a.mp3',
          'work/特典/a.mp3',
          'work/24bit/a.wav',
        ], _preference()),
        isNull,
      );
    });

    test('enters a format three levels below the root', () {
      final selected = _pick([
        'work/本体/SEなし/mp3/a.mp3',
        'work/本体/SEあり/wav/a.wav',
      ], _preference());
      expect(selected?.normalized, 'work/本体/SEなし/mp3');
    });

    test('does not jump again after the user returns home', () {
      final index = _index(['work/mp3/a.mp3', 'work/wav/a.wav']);

      expect(index.jumpToPreferredAudioFolder(_preference()), isTrue);
      expect(index.currentFolder?.name, 'mp3');

      index.goHome();
      expect(index.isHome, isTrue);
      expect(index.jumpToPreferredAudioFolder(_preference()), isTrue);

      index.stepOut();
      expect(index.isHome, isTrue);
    });
  });

  group('detail entry', () {
    late Directory hiveDirectory;
    late Box<dynamic> settingsBox;

    setUpAll(() async {
      hiveDirectory = await Directory.systemTemp.createTemp(
        'kikoenai_audio_folder_',
      );
      Hive.init(hiveDirectory.path);
      settingsBox = await Hive.openBox<dynamic>(BoxNames.settings);
    });

    tearDownAll(() async {
      await Hive.close();
      await hiveDirectory.delete(recursive: true);
    });

    tearDown(() async {
      await settingsBox.clear();
    });

    test('opens the preferred folder from stored settings', () async {
      await settingsBox.put(StorageKeys.audioFormatPreference, ['wav', 'mp3']);
      final preference = AudioFolderPreference.fromStorage(settingsBox);

      expect(preference.formats.first, 'wav');
      expect(
        _pick(['work/mp3/a.mp3', 'work/wav/a.wav'], preference)?.name,
        'wav',
      );
    });
  });
}
