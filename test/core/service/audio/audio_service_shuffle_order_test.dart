import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/audio/audio_service.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:media_kit/media_kit.dart';

class _MemoryPlayer extends PlatformPlayer {
  _MemoryPlayer() : super(configuration: const PlayerConfiguration());

  final List<Playable> opened = [];

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    opened.add(playable);
  }

  @override
  Future<void> setPlaylistMode(PlaylistMode playlistMode) async {}

  @override
  Future<void> setVolume(double volume) async {}
}

List<MediaItem> _items(int count) => List.generate(
  count,
  (index) => MediaItem(
    id: 'track-$index',
    title: 'Track $index',
    extras: {'url': 'https://example.test/$index.mp3'},
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late Box<dynamic> settings;
  late _MemoryPlayer backend;
  late MyAudioHandler handler;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('shuffle_handler_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    Hive.init(directory.path);
    settings = await Hive.openBox<dynamic>('settings');
    AppStorage.settingsBox = settings;
    await settings.put(StorageKeys.ignoreAudioFocus, true);
    backend = _MemoryPlayer();
    handler = MyAudioHandler(Player(platformPlayer: backend));
  });

  tearDown(() async {
    await backend.dispose();
    await Hive.close();
    await KikoenaiLogOutput.flush();
    await directory.delete(recursive: true);
  });

  test('random next does not repeat before the queue is played once', () async {
    await handler.setRepeatMode(AudioServiceRepeatMode.all);
    await handler.setShuffleMode(AudioServiceShuffleMode.all);
    final items = _items(5);
    await handler.loadPlaylist(items, autoPlay: false);

    final played = <String>{handler.mediaItem.value!.id};
    for (var i = 0; i < items.length - 1; i++) {
      await handler.skipToNext();
      played.add(handler.mediaItem.value!.id);
    }

    expect(played, items.map((item) => item.id).toSet());
    final previousId = handler.mediaItem.value!.id;
    await handler.skipToNext();
    expect(handler.mediaItem.value!.id, isNot(previousId));
    expect(handler.queue.value, items);
  });

  test('previous and next follow the shuffled cursor', () async {
    await handler.setRepeatMode(AudioServiceRepeatMode.all);
    await handler.setShuffleMode(AudioServiceShuffleMode.all);
    await handler.loadPlaylist(_items(4), autoPlay: false);
    await handler.skipToNext();
    final second = handler.mediaItem.value!.id;
    await handler.skipToNext();
    final third = handler.mediaItem.value!.id;

    expect(handler.canSkipToPrevious, isTrue);
    await handler.skipToPrevious();
    expect(handler.mediaItem.value!.id, second);
    await handler.skipToNext();
    expect(handler.mediaItem.value!.id, third);
  });

  test(
    'saved order resumes from the same cursor after reopening Hive',
    () async {
      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      final items = _items(5);
      await handler.loadPlaylist(items, autoPlay: false);
      await handler.skipToNext();
      final currentIndex = handler.playbackState.value.queueIndex!;
      final snapshot = Map.of(
        settings.get(StorageKeys.playerShuffleOrder) as Map,
      );
      await handler.skipToNext();
      final expectedNextIndex = handler.playbackState.value.queueIndex;
      await settings.put(StorageKeys.playerShuffleOrder, snapshot);

      await backend.dispose();
      await Hive.close();
      settings = await Hive.openBox<dynamic>('settings');
      AppStorage.settingsBox = settings;
      backend = _MemoryPlayer();
      handler = MyAudioHandler(Player(platformPlayer: backend));
      await handler.initPlayback(
        initialPlaylist: items,
        initialIndex: currentIndex,
        initialPosition: Duration.zero,
        volume: 1,
        repeatMode: AudioServiceRepeatMode.all,
        shuffleEnabled: true,
      );
      await handler.skipToNext();

      expect(handler.playbackState.value.queueIndex, expectedNextIndex);
    },
  );

  test(
    'manual selection keeps the previous item and reorders current index',
    () async {
      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      final items = _items(4);
      await handler.loadPlaylist(items, autoPlay: false);
      await handler.skipToNext();
      final previous = handler.mediaItem.value!.id;
      await handler.skipToQueueItem(3);
      expect(handler.mediaItem.value!.id, 'track-3');
      await handler.skipToPrevious();
      expect(handler.mediaItem.value!.id, previous);

      await handler.customAction('reorderQueue', {
        'oldIndex': 0,
        'newIndex': 3,
      });
      expect(handler.queue.value.map((item) => item.id), [
        'track-1',
        'track-2',
        'track-3',
        'track-0',
      ]);
    },
  );

  test(
    'adding while shuffled does not reinsert tracks already played this round',
    () async {
      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await handler.loadPlaylist(_items(4), autoPlay: false);
      await handler.skipToNext();
      final alreadyPlayed = handler.mediaItem.value!.id;
      await handler.addQueueItem(_items(5).last);

      final pending = <String>{};
      for (var i = 0; i < 3; i++) {
        await handler.skipToNext();
        pending.add(handler.mediaItem.value!.id);
      }
      expect(pending, contains('track-4'));
      expect(pending, isNot(contains(alreadyPlayed)));
    },
  );
}
