import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'lyrics_match_candidates.dart';
import 'search_lyrics_service.dart';

/// 字幕匹配策略的抽象基类。
///
/// 采用策略模式（Strategy Pattern）设计，允许定义不同的规则来将音频文件（[MediaItem]）
/// 与字幕文件（[FileNode]）进行关联绑定。
/// 通过静态方法 [match] 按责任链顺序执行策略，逐步提高匹配覆盖率。
abstract class MatchLyrics {
  Box<dynamic> get settingBox => AppStorage.settingsBox;

  /// 给个唯一标识，TODO 后续可以直接用其做成多语言的Key
  String get strategyId;

  /// 检查该策略是否适用
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList);

  /// 执行匹配
  /// [currentMatches] : 上一轮策略已匹配的结果 (Key: audio.id, Value: lyricNode)
  Map<String, FileNode> matchLyrics(
    List<MediaItem> playList,
    List<FileNode> lyricList,
  );

  /// 默认匹配策略
  static List<MatchLyrics> _defaultStrategies = [
    CacheMatch(),
    AccurateMatch(),
    FuzzyMatch(),
    SequenceMatch(),
  ];

  /// 暴露当前全局生效的策略链
  static List<MatchLyrics> get defaultStrategies => _defaultStrategies;

  /// 覆写全局默认策略
  /// 可在应用初始化时调用此方法，注入自定义策略或调整执行顺序
  static void overrideDefaultStrategies(List<MatchLyrics> strategies) {
    _defaultStrategies = strategies;
  }

  /// 匹配入口，执行责任链进行匹配
  static Map<String, FileNode> match(
    List<MediaItem> playList,
    List<FileNode> lyricList,
  ) {
    final runStrategies = defaultStrategies;

    final Map<String, FileNode> finalResults = {};
    // 拷贝一份播放列表，用于在责任链中逐步剔除已匹配的音频
    final List<MediaItem> pendingPlayList = List.of(playList);

    for (final strategy in runStrategies) {
      // 待匹配列表为空时提前结束责任链
      if (pendingPlayList.isEmpty) break;

      if (strategy.isMatch(pendingPlayList, lyricList)) {
        var newMatches = strategy.matchLyrics(pendingPlayList, lyricList);

        if (newMatches.isNotEmpty) {
          finalResults.addAll(newMatches);
          // 从待匹配列表中剔除刚刚匹配成功的音频
          pendingPlayList.removeWhere(
            (audio) => newMatches.containsKey(audio.id),
          );
        }
      }
    }
    return finalResults;
  }

  static void persistMatchResults(Map<String, FileNode> currentResults) {
    if (currentResults.isEmpty) return;

    final box = AppStorage.lyricMatchBox;
    final Map<String, FileNode> entriesToUpdate = {};

    currentResults.forEach((audioId, lyricNode) {
      final cachedNode = box.get(audioId);
      // 无 hash 的本地字幕也必须能够新增或更换手动绑定。
      if (cachedNode == null ||
          LyricsMatchCandidates.identity(cachedNode) !=
              LyricsMatchCandidates.identity(lyricNode)) {
        entriesToUpdate[audioId] = lyricNode;
      }
    });

    if (entriesToUpdate.isNotEmpty) {
      box.putAll(entriesToUpdate);
    }
  }

  /// 提供策略入口，用于用户选择某种具体策略进行快速手动粗排。(供字幕匹配弹窗使用）
  /// 直接接收由调用方传入的策略实例，方便后续策略拓展
  static Map<String, FileNode> matchBySingleStrategy({
    required List<MediaItem> playList,
    required List<FileNode> lyricList,
    required MatchLyrics strategy, // 核心改变：直接接收基类实例
  }) {
    if (playList.isEmpty || lyricList.isEmpty) return {};

    if (strategy.isMatch(playList, lyricList)) {
      return strategy.matchLyrics(playList, lyricList);
    }

    return {};
  }
}

/// 缓存匹配策略。
/// 优先读取本地持久化的匹配记录，跳过已匹配过的音频，避免重复计算。
/// 从独立的 Hive Box 中读取 [audio.id] 与 [FileNode] 的映射关系。
/// 验证缓存中的字幕文件是否仍然存在于当前的字幕列表中。
class CacheMatch extends MatchLyrics {
  Box<FileNode> get matchBox => AppStorage.lyricMatchBox;
  @override
  String get strategyId => "缓存策略";
  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    if (playList.isEmpty || matchBox.isEmpty) return false;

    return playList.any((audio) => matchBox.containsKey(audio.id));
  }

  @override
  Map<String, FileNode> matchLyrics(
    List<MediaItem> playList,
    List<FileNode> lyricList,
  ) {
    final results = <String, FileNode>{};

    final availableLyrics = {
      for (final node in lyricList) LyricsMatchCandidates.identity(node): node,
    };
    final byHash = <String, List<FileNode>>{};
    for (final node in lyricList) {
      final hash = node.hash;
      if (hash != null && hash.isNotEmpty) {
        (byHash[hash] ??= []).add(node);
      }
    }

    for (var audio in playList) {
      final cachedLyricNode = matchBox.get(audio.id);

      if (cachedLyricNode != null) {
        var currentNode =
            availableLyrics[LyricsMatchCandidates.identity(cachedLyricNode)];
        // 旧缓存可能没有目录字段，只在非空 hash 唯一时兼容恢复。
        if (currentNode == null && cachedLyricNode.path == null) {
          currentNode = LyricsMatchCandidates.unique(
            byHash[cachedLyricNode.hash] ?? const <FileNode>[],
          );
        }
        if (currentNode != null) results[audio.id] = currentNode;
      }
    }
    return results;
  }
}

/// 精确标题匹配策略。
///
/// 目的: 找出音频与字幕标题完全一致的配对。
/// 先按目录层级筛选，再比较归一化标题。同名候选仍有歧义时交由手动绑定。
/// 同一字幕可以用于不同音频格式的版本。
/// 适用条件: 音频列表和字幕列表均不为空即可启用。
class AccurateMatch extends MatchLyrics {
  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    return playList.isNotEmpty && lyricList.isNotEmpty;
  }

  @override
  Map<String, FileNode> matchLyrics(
    List<MediaItem> playList,
    List<FileNode> lyricList,
  ) {
    final results = <String, FileNode>{};

    final candidates = LyricsMatchCandidates(lyricList);
    final titles = {
      for (final node in lyricList)
        node: LyricsDataProcess.titleFingerprint(node.title),
    };

    for (var audio in playList) {
      final title = LyricsDataProcess.titleFingerprint(audio.title);
      if (title.isEmpty) continue;
      final match = LyricsMatchCandidates.unique(
        candidates.forAudio(audio).where((node) => titles[node] == title),
      );
      if (match != null) results[audio.id] = match;
    }
    return results;
  }

  @override
  String get strategyId => "精确匹配";
}

/// 模糊相似度匹配策略。
///
/// 目的: 处理因文件名带有冗余信息（如 "Song_Name_Lyric" vs "Song Name"）导致精确匹配失败的情况。
/// 机制: 采用 Sørensen–Dice 系数算法，通过提取字符串的相邻双字符组合（Bigrams）来计算文本相似度。
/// 分数在 0.0 到 1.0 之间，若超过设定的 [threshold] 且为当前最高分，则认为匹配成功。
/// 为提高性能，在遍历前统一预计算所有可用字幕的 Bigrams 集合。
/// 适用条件: 音频列表和字幕列表均不为空即可启用。
class FuzzyMatch extends MatchLyrics {
  /// 相似度阈值。默认为 0.6。
  /// 设置过低可能导致错误匹配，设置过高会导致容错率降低。
  final double threshold;

  FuzzyMatch({this.threshold = 0.6});

  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    return playList.isNotEmpty && lyricList.isNotEmpty;
  }

  @override
  Map<String, FileNode> matchLyrics(
    List<MediaItem> playList,
    List<FileNode> lyricList,
  ) {
    final results = <String, FileNode>{};
    final candidates = LyricsMatchCandidates(lyricList);
    final lyricBigramsMap = <FileNode, Set<String>>{};
    for (var lyric in lyricList) {
      lyricBigramsMap[lyric] = _getBigrams(
        LyricsDataProcess.titleFingerprint(lyric.title),
      );
    }
    for (var audio in playList) {
      final bestMatches = <FileNode>[];
      double highestScore = 0.0;
      final audioBigrams = _getBigrams(
        LyricsDataProcess.titleFingerprint(audio.title),
      );
      for (var lyric in candidates.forAudio(audio)) {
        final lyricBigrams = lyricBigramsMap[lyric]!;
        final score = _calculateDiceCoefficient(
          s1Bigrams: audioBigrams,
          s2Bigrams: lyricBigrams,
        );
        if (score < threshold) continue;
        if (score > highestScore) {
          highestScore = score;
          bestMatches.clear();
        }
        if (score == highestScore) bestMatches.add(lyric);
      }
      final bestMatch = LyricsMatchCandidates.unique(bestMatches);
      if (bestMatch != null) {
        results[audio.id] = bestMatch;
      }
    }
    return results;
  }

  /// 算法简化：由于外层已经预计算好，直接传 Set
  double _calculateDiceCoefficient({
    required Set<String> s1Bigrams,
    required Set<String> s2Bigrams,
  }) {
    if (s1Bigrams.isEmpty || s2Bigrams.isEmpty) return 0.0;

    int intersection = 0;
    // 优化：总是遍历较小的那个 Set 来计算交集
    final smallerSet = s1Bigrams.length < s2Bigrams.length
        ? s1Bigrams
        : s2Bigrams;
    final largerSet = s1Bigrams.length < s2Bigrams.length
        ? s2Bigrams
        : s1Bigrams;

    for (var item in smallerSet) {
      if (largerSet.contains(item)) {
        intersection++;
      }
    }

    return (2.0 * intersection) / (s1Bigrams.length + s2Bigrams.length);
  }

  /// 生成字符双元组 (Bigrams)
  Set<String> _getBigrams(String input) {
    Set<String> bigrams = {};
    String refined = input.replaceAll(' ', '');

    // 边界处理：太短的字符串，或者去除空格后只剩1个字符的
    if (refined.isEmpty) return {};
    if (refined.length < 2) return {refined};

    for (int i = 0; i < refined.length - 1; i++) {
      bigrams.add(refined.substring(i, i + 2));
    }
    return bigrams;
  }

  @override
  String get strategyId => "模糊匹配";
}

/// 序号提取匹配策略 (兜底策略)。
///
/// 目的: 提取音频和字幕文件名中包含的数字序号（如 "01", "Track 2"）进行匹配。
/// 机制: 利用正则表达式提取标题中出现的首组数字并转化为整型（抹平 "01" 与 "1" 的差异）。
/// 若未匹配音频和未使用字幕具有相同的序号，则进行绑定。
/// 适用条件: 一轮匹配下来如果还有未匹配的音频，且未匹配的字幕不为空的话则进行序号强行绑定，后续提供手动匹配交给用户进行匹配
class SequenceMatch extends MatchLyrics {
  // 匹配字符串中的连续数字
  static final _numberRegex = RegExp(r'\d+');

  int? _extractSequenceNumber(String title) {
    final match = _numberRegex.firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }

  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    return playList.isNotEmpty && lyricList.isNotEmpty;
  }

  @override
  Map<String, FileNode> matchLyrics(
    List<MediaItem> playList,
    List<FileNode> lyricList,
  ) {
    final results = <String, FileNode>{};

    final candidates = LyricsMatchCandidates(lyricList);
    final sequences = {
      for (final lyric in lyricList)
        lyric: _extractSequenceNumber(
          LyricsDataProcess.titleFingerprint(lyric.title),
        ),
    };

    for (var audio in playList) {
      final audioSeq = _extractSequenceNumber(
        LyricsDataProcess.titleFingerprint(audio.title),
      );
      if (audioSeq == null) continue;
      final match = LyricsMatchCandidates.unique(
        candidates.forAudio(audio).where((node) => sequences[node] == audioSeq),
      );
      if (match != null) results[audio.id] = match;
    }

    return results;
  }

  @override
  String get strategyId => "序号匹配";
}
