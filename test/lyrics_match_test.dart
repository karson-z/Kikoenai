import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/service/lyrics/match_lyrics_service.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/storage/hive_key.dart';

void main() {
  const String matchBoxName = 'lyricMatchBox';
  const String settingsBoxName = 'settingsBox';

  FileNode buildLyricNode({required String title, String? hash}) {
    return FileNode(
      type: NodeType.text,
      title: title,
      hash: hash ?? title.hashCode.toString(),
    );
  }

  MediaItem buildMediaItem({required String id, required String title}) {
    return MediaItem(
      id: id,
      title: title,
    );
  }

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_ce_test_suite_');
    Hive.init(tempDir.path);

    Hive.registerAdapter(NodeTypeAdapter());
    Hive.registerAdapter(NodeStatusAdapter());
    Hive.registerAdapter(FileNodeAdapter());

    AppStorage.settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    AppStorage.lyricMatchBox = await Hive.openBox<FileNode>(matchBoxName);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    await Hive.box<dynamic>(settingsBoxName).clear();
    await Hive.box<FileNode>(matchBoxName).clear();
  });

  group('MatchLyrics.match 基类静态方法测试', () {
    test('责任链执行：按照预定顺序逐层拦截并建立映射', () {
      final audioAccurate = buildMediaItem(id: 'a1', title: 'Exact Title');
      final audioFuzzy = buildMediaItem(id: 'a2', title: 'Fuzzy Match');
      final audioSeq = buildMediaItem(id: 'a3', title: '03 Track');

      final lyricAccurate = buildLyricNode(title: 'Exact Title', hash: 'h1');
      final lyricFuzzy = buildLyricNode(title: 'Fuzzy Match Lyric', hash: 'h2');
      final lyricSeq = buildLyricNode(title: 'Track 3 Sub', hash: 'h3');

      final results = MatchLyrics.match(
        [audioAccurate, audioFuzzy, audioSeq],
        [lyricAccurate, lyricFuzzy, lyricSeq],
      );

      expect(results.length, 3);
      expect(results['a1'], lyricAccurate);
      expect(results['a2'], lyricFuzzy);
      expect(results['a3'], lyricSeq);
    });

    test('持久化写入：仅当数据发生变化时执行写入操作', () async {
      final audio = buildMediaItem(id: 'a1', title: 'Song');
      final lyricOld = buildLyricNode(title: 'Song', hash: 'h_old');
      final lyricNew = buildLyricNode(title: 'Song', hash: 'h_new');

      final box = Hive.box<FileNode>(matchBoxName);
      await box.put(audio.id, lyricOld);

      // 模拟哈希变更的情况
      MatchLyrics.persistMatchResults({'a1': lyricNew});
      expect(box.get('a1')?.hash, 'h_new');

      // 模拟哈希未变的情况
      MatchLyrics.persistMatchResults({'a1': lyricNew});
      // 验证未抛出异常，业务逻辑自动拦截无效写入
      expect(box.get('a1')?.hash, 'h_new');
    });

    test('弹窗回调触发：存在未匹配音频且设置允许', () {
      AppStorage.settingsBox.put(StorageKeys.autoManualLyricsMatch, true);

      final audio = buildMediaItem(id: 'a1', title: 'No Match Audio');
      final lyric = buildLyricNode(title: 'Different Lyric', hash: 'h1');

      bool callbackFired = false;

      MatchLyrics.match(
        [audio],
        [lyric],
        onShowManualMatchDialog: (p, a, c) {
          callbackFired = true;
          expect(p.length, 1);
          expect(a.length, 1);
          expect(c.isEmpty, isTrue);
        },
      );

      expect(callbackFired, isTrue);
    });

    test('弹窗回调拦截：存在未匹配音频但设置禁止', () {
      AppStorage.settingsBox.put(StorageKeys.autoManualLyricsMatch, false);

      final audio = buildMediaItem(id: 'a1', title: 'No Match Audio');
      final lyric = buildLyricNode(title: 'Different Lyric', hash: 'h1');

      bool callbackFired = false;

      MatchLyrics.match(
        [audio],
        [lyric],
        onShowManualMatchDialog: (p, a, c) => callbackFired = true,
      );

      expect(callbackFired, isFalse);
    });
  });

  group('CacheMatch 策略测试', () {
    final strategy = CacheMatch();

    test('路径拦截：音频列表或 matchBox 为空时直接返回', () {
      expect(strategy.isMatch([], [buildLyricNode(title: 'L')]), isFalse);
    });

    test('缓存命中：缓存数据存在于当前可用列表中', () async {
      final audio = buildMediaItem(id: 'a1', title: 'Song');
      final validLyric = buildLyricNode(title: 'Song', hash: 'h_valid');
      await Hive.box<FileNode>(matchBoxName).put(audio.id, validLyric);

      final result = strategy.matchLyrics([audio], [validLyric]);
      expect(result['a1'], validLyric);
    });

    test('缓存失效：缓存数据对应的实例已不在可用列表中', () async {
      final audio = buildMediaItem(id: 'a1', title: 'Song');
      final oldLyric = buildLyricNode(title: 'Song', hash: 'h_old');
      await Hive.box<FileNode>(matchBoxName).put(audio.id, oldLyric);

      final newLyric = buildLyricNode(title: 'Song', hash: 'h_new');
      final result = strategy.matchLyrics([audio], [newLyric]);
      expect(result.isEmpty, isTrue);
    });

    test('前置占用：音频已被 currentMatches 记录', () async {
      final audio = buildMediaItem(id: 'a1', title: 'Song');
      final lyric = buildLyricNode(title: 'Song', hash: 'h1');
      await Hive.box<FileNode>(matchBoxName).put(audio.id, lyric);

      final result = strategy.matchLyrics([audio], [lyric], {'a1': lyric});
      expect(result.isEmpty, isTrue);
    });
  });

  group('AccurateMatch 策略测试', () {
    final strategy = AccurateMatch();

    test('精确命中：标题完全一致建立一一映射', () {
      final audio = buildMediaItem(id: 'a1', title: 'Exact Title');
      final lyric = buildLyricNode(title: 'Exact Title');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result['a1'], lyric);
    });

    test('资源抢占防范：同名音频竞争单列字幕', () {
      final audio1 = buildMediaItem(id: 'a1', title: 'Shared Title');
      final audio2 = buildMediaItem(id: 'a2', title: 'Shared Title');
      final lyric = buildLyricNode(title: 'Shared Title');

      final result = strategy.matchLyrics([audio1, audio2], [lyric]);
      expect(result.containsKey('a1'), isTrue);
      expect(result.containsKey('a2'), isFalse);
    });

    test('边界测试：空字符标题', () {
      final audio = buildMediaItem(id: 'a1', title: '');
      final lyric = buildLyricNode(title: '');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result['a1'], lyric);
    });

    test('边界测试：特殊符号与转义字符', () {
      const title = 'Song\nName\t⭐[Cover]';
      final audio = buildMediaItem(id: 'a1', title: title);
      final lyric = buildLyricNode(title: title);
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result['a1'], lyric);
    });
  });

  group('FuzzyMatch 策略测试', () {
    final strategy = FuzzyMatch(threshold: 0.6);

    test('常规模糊：冗余字符影响下相似度达标', () {
      final audio = buildMediaItem(id: 'a1', title: 'Beautiful World');
      final lyric = buildLyricNode(title: 'Beautiful_World_Lyric');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result.length, 1);
    });

    test('阈值拦截：相似度低于阈值', () {
      final audio = buildMediaItem(id: 'a1', title: 'Short');
      final lyric = buildLyricNode(title: 'Completely Different Long Title');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result.isEmpty, isTrue);
    });

    test('优胜劣汰：取相似度最高的分支', () {
      final audio = buildMediaItem(id: 'a1', title: 'Target Song');
      final lowMatch = buildLyricNode(title: 'Target Song Demo');
      final highMatch = buildLyricNode(title: 'Target Song Lyric');

      final result = strategy.matchLyrics([audio], [lowMatch, highMatch]);
      expect(result['a1'], highMatch);
    });

    test('前置占用：已被 previous 阶段占用的字幕直接排除', () {
      final audio = buildMediaItem(id: 'a1', title: 'Fuzzy Title');
      final lyric = buildLyricNode(title: 'Fuzzy Title Sub');

      final result = strategy.matchLyrics([audio], [lyric], {'a0': lyric});
      expect(result.isEmpty, isTrue);
    });

    test('内部占用：当前循环内的二次资源抢夺拦截', () {
      final audio1 = buildMediaItem(id: 'a1', title: 'Title Match A');
      final audio2 = buildMediaItem(id: 'a2', title: 'Title Match B');
      final lyric = buildLyricNode(title: 'Title Match Sub');

      final result = strategy.matchLyrics([audio1, audio2], [lyric]);
      expect(result.containsKey('a1'), isTrue);
      expect(result.containsKey('a2'), isFalse);
    });

    test('边界测试：标题过短或由全空格组成', () {
      final audioEmpty = buildMediaItem(id: 'a1', title: '   ');
      final lyricEmpty = buildLyricNode(title: '   ');
      expect(strategy.matchLyrics([audioEmpty], [lyricEmpty]).isEmpty, isTrue);

      final audioChar = buildMediaItem(id: 'a2', title: 'A');
      final lyricChar = buildLyricNode(title: 'A');
      expect(strategy.matchLyrics([audioChar], [lyricChar])['a2'], lyricChar);
    });
  });

  group('SequenceMatch 策略测试', () {
    final strategy = SequenceMatch();

    test('常规序号：提取首组连续数字匹配', () {
      final audio = buildMediaItem(id: 'a1', title: '01 Track');
      final lyric = buildLyricNode(title: 'Track 1 Sub');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result['a1'], lyric);
    });

    test('重复序号过滤：同序号仅保留首个被遍历对象', () {
      final audio = buildMediaItem(id: 'a1', title: 'Track 02');
      final lyric1 = buildLyricNode(title: '02 Sub', hash: 'h1');
      final lyric2 = buildLyricNode(title: '02 Copy', hash: 'h2');

      final result = strategy.matchLyrics([audio], [lyric1, lyric2]);
      expect(result['a1']?.hash, 'h1');
    });

    test('无序号拦截：不含数字的文本直接跳过', () {
      final audio = buildMediaItem(id: 'a1', title: 'Text Only');
      final lyric = buildLyricNode(title: 'Text Sub');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result.isEmpty, isTrue);
    });

    test('边界测试：前导零差异抹平', () {
      final audio = buildMediaItem(id: 'a1', title: 'Track 007');
      final lyric = buildLyricNode(title: 'Song 7');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result['a1'], lyric);
    });

    test('边界测试：超出整型范围的超大数字截断拦截', () {
      final massiveNum = '9' * 30;
      final audio = buildMediaItem(id: 'a1', title: massiveNum);
      final lyric = buildLyricNode(title: massiveNum);
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result.isEmpty, isTrue);
    });

    test('边界测试：浮点数或版本号提取首部整数', () {
      final audio = buildMediaItem(id: 'a1', title: 'Version 1.5');
      final lyric = buildLyricNode(title: 'Track 1');
      final result = strategy.matchLyrics([audio], [lyric]);
      expect(result['a1'], lyric);
    });
  });
}