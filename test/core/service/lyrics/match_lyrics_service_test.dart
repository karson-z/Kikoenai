import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/core/service/lyrics/match_lyrics_service.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

FileNode _lyric(String path, {String? root, String? hash}) => FileNode(
  type: NodeType.text,
  title: NodeFolder.baseName(path),
  path: path,
  rootPath: root,
  hash: hash,
);

MediaItem _audio(String path, {String? root, String? title}) =>
    PlaybackItem.fromFileNode(
      FileNode(
        type: NodeType.audio,
        title: title ?? NodeFolder.baseName(path),
        path: path,
        rootPath: root,
        mediaStreamUrl: 'https://stream.example/api/opaque-id',
      ),
    ).toMediaItem();

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('lyrics_match_');
    Hive.init(directory.path);
    Hive.registerAdapter(NodeTypeAdapter());
    Hive.registerAdapter(NodeStatusAdapter());
    Hive.registerAdapter(NodeSourceAdapter());
    Hive.registerAdapter(FileNodeAdapter());
    AppStorage.settingsBox = await Hive.openBox<dynamic>('settings');
    AppStorage.lyricMatchBox = await Hive.openBox<FileNode>('lyrics');
  });

  tearDown(() async {
    await AppStorage.lyricMatchBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  for (final strategy in [AccurateMatch(), FuzzyMatch(), SequenceMatch()]) {
    test('${strategy.strategyId} keeps repeated names in their folders', () {
      final a = _lyric('/work/本編/01.srt');
      final b = _lyric('/work/特典/01.srt');
      final audioA = _audio('/work/本編/01.mp3');
      final audioB = _audio('/work/特典/01.mp3');
      for (final lyrics in [
        [a, b],
        [b, a],
      ]) {
        expect(strategy.matchLyrics([audioB, audioA], lyrics), {
          audioA.id: a,
          audioB.id: b,
        });
      }
    });

    test('${strategy.strategyId} resolves mirrored independent roots', () {
      final a = _lyric('/subtitles/RJ1/Disc1/01.srt', root: '/subtitles');
      final b = _lyric('/subtitles/RJ1/Disc2/01.srt', root: '/subtitles');
      final audioA = _audio('/audio/RJ1/Disc1/01.mp3', root: '/audio');
      final audioB = _audio('/audio/RJ1/Disc2/01.mp3', root: '/audio');
      expect(strategy.matchLyrics([audioB, audioA], [a, b]), {
        audioA.id: a,
        audioB.id: b,
      });
    });

    test('${strategy.strategyId} leaves equally plausible duplicates open', () {
      expect(
        strategy.matchLyrics(
          [const MediaItem(id: 'opaque-audio', title: '01')],
          [_lyric('/A/01.srt'), _lyric('/B/01.srt')],
        ),
        isEmpty,
      );
    });

    test('${strategy.strategyId} uses a nested subtitle directory', () {
      final lyric = _lyric('/work/Disc1/字幕/01.srt', root: '/work');
      final other = _lyric('/work/Disc2/字幕/01.srt', root: '/work');
      final audio = _audio('/work/Disc1/01.mp3', root: '/work');
      expect(strategy.matchLyrics([audio], [other, lyric]), {audio.id: lyric});
    });

    test(
      '${strategy.strategyId} respects parents above repeated leaf folders',
      () {
        final lyric = _lyric('/work/A/SEなし/字幕/01.srt', root: '/work');
        final other = _lyric('/work/B/SEなし/01.srt', root: '/work');
        final audio = _audio('/work/A/SEなし/01.mp3', root: '/work');
        expect(strategy.matchLyrics([audio], [other, lyric]), {
          audio.id: lyric,
        });
      },
    );
  }

  test('entire chain cannot reintroduce ambiguous matches in fallback', () {
    expect(
      MatchLyrics.match(
        [const MediaItem(id: 'opaque-audio', title: '01')],
        [_lyric('/A/01.srt'), _lyric('/B/01.srt')],
      ),
      isEmpty,
    );
  });

  test('local fuzzy match wins over an exact title in another folder', () {
    final audio = _audio('/work/A/01 long recording.mp3');
    final local = _lyric('/work/A/01 long recording translated.srt');
    final other = _lyric('/work/B/01 long recording.srt');
    expect(MatchLyrics.match([audio], [other, local]), {audio.id: local});
  });

  test('unique global fallback and sharing across formats still work', () {
    final lyric = _lyric('/subtitles/01.srt');
    final mp3 = _audio('/audio/mp3/01.mp3');
    final wav = _audio('/audio/wav/01.wav');
    expect(MatchLyrics.match([mp3, wav], [lyric]), {
      mp3.id: lyric,
      wav.id: lyric,
    });
  });

  test('real remote tree paths survive opaque playback URLs', () {
    final index = FileNodeLibraryIndex.fromRemoteTree(
      contentId: const SiteContentId(siteId: 'site-a', remoteId: '123'),
      roots: [
        for (final folder in ['A', 'B'])
          FileNode(
            type: NodeType.folder,
            title: folder,
            children: [
              FileNode(
                type: NodeType.audio,
                title: '01.mp3',
                hash: 'audio-$folder',
                mediaStreamUrl: 'https://stream/$folder',
              ),
              FileNode(
                type: NodeType.text,
                title: '01.srt',
                hash: 'subtitle-$folder',
                mediaStreamUrl: 'https://subtitle/$folder',
              ),
            ],
          ),
      ],
    );
    final audio = index.nodeByPath.values
        .where((node) => node.isAudio)
        .map((node) => PlaybackItem.fromFileNode(node).toMediaItem())
        .toList();
    final matches = MatchLyrics.match(audio, index.collectAllSubtitles());
    expect(matches['audio-A']!.hash, 'subtitle-A');
    expect(matches['audio-B']!.hash, 'subtitle-B');
  });

  test('legacy local file URI handles encoding, separators and query', () {
    const audio = MediaItem(
      id: 'legacy',
      title: '01.mp3',
      extras: {'url': 'file:///work/%E6%9C%AC%E7%B7%A8/01.mp3?token=ignore'},
    );
    final local = _lyric(r'/work\本編\01.srt');
    final other = _lyric('/work/特典/01.srt');
    expect(AccurateMatch().matchLyrics([audio], [other, local]), {
      audio.id: local,
    });
  });

  test('manual binding takes precedence over directory matching', () async {
    final audio = _audio('/work/A/01.mp3');
    final local = _lyric('/work/A/01.srt');
    final manual = _lyric('/work/B/01.srt');
    MatchLyrics.persistMatchResults({audio.id: manual});
    await AppStorage.lyricMatchBox.flush();
    expect(MatchLyrics.match([audio], [local, manual]), {audio.id: manual});
    MatchLyrics.persistMatchResults({audio.id: local});
    await AppStorage.lyricMatchBox.flush();
    expect(MatchLyrics.match([audio], [local, manual]), {audio.id: local});
  });

  test(
    'missing cached file with null hash does not match another file',
    () async {
      final audio = _audio('/work/A/01.mp3');
      await AppStorage.lyricMatchBox.put(audio.id, _lyric('/old/01.srt'));
      expect(
        CacheMatch().matchLyrics([audio], [_lyric('/new/02.srt')]),
        isEmpty,
      );
    },
  );

  test(
    'legacy manual bindings restore only an unambiguous nonempty hash',
    () async {
      final audio = _audio('/work/A/01.mp3');
      await AppStorage.lyricMatchBox.put(
        audio.id,
        FileNode(type: NodeType.text, title: 'manual', hash: 'saved-hash'),
      );
      final current = _lyric('/work/B/01.srt', hash: 'saved-hash');
      expect(CacheMatch().matchLyrics([audio], [current]), {audio.id: current});
      expect(
        CacheMatch().matchLyrics(
          [audio],
          [current, _lyric('/work/C/01.srt', hash: 'saved-hash')],
        ),
        isEmpty,
      );
    },
  );

  test('titles preserve meaningful dot-separated names', () {
    final audio = _audio('/work/01.part.one.mp3');
    final first = _lyric('/work/01.part.one.srt');
    final second = _lyric('/work/01.part.two.srt');
    expect(AccurateMatch().matchLyrics([audio], [first, second]), {
      audio.id: first,
    });
  });
}
