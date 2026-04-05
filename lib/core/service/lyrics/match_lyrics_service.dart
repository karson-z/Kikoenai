import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import '../../model/file_node.dart';

/// 字幕匹配策略的抽象基类。
///
/// 采用策略模式（Strategy Pattern）设计，允许定义不同的规则来将音频文件（[MediaItem]）
/// 与字幕文件（[FileNode]）进行关联绑定。
/// 通过静态方法 [match] 按责任链顺序执行策略，逐步提高匹配覆盖率。
abstract class MatchLyrics {

  Box<dynamic> get settingBox => AppStorage.settingsBox;

  /// 检查该策略是否适用
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList);

  /// 执行匹配
  /// [currentMatches] : 上一轮策略已匹配的结果 (Key: audio.id, Value: lyricNode)
  Map<String, FileNode> matchLyrics(
      List<MediaItem> playList,
      List<FileNode> lyricList, [
        Map<String, FileNode> currentMatches = const {}
      ]);

  /// 统一入口：按顺序执行策略链
  /// [onShowManualMatchDialog] : 当存在未匹配的音频且设置允许时，触发手动匹配弹窗的回调
  static Map<String, FileNode> match(
      List<MediaItem> playList,
      List<FileNode> lyricList, {
        List<MatchLyrics>? strategies,
        void Function(
            List<MediaItem> playlist,
            List<FileNode> availableSubtitles,
            Map<String, FileNode> currentMapping,
            )? onShowManualMatchDialog,
      }) {
    final runStrategies = strategies ??
        [
          CacheMatch(),
          AccurateMatch(),
          FuzzyMatch(),
          SequenceMatch(),
        ];

    final Map<String, FileNode> finalResults = {};

    for (final strategy in runStrategies) {
      if (strategy.isMatch(playList, lyricList)) {
        var newMatches = strategy.matchLyrics(playList, lyricList, finalResults);
        newMatches.forEach((audioId, lyricNode) {
          if (!finalResults.containsKey(audioId)) {
            finalResults[audioId] = lyricNode;
          }
        });
      }
    }

    persistMatchResults(finalResults);

    final unmatchedAudios = playList
        .where((audio) => !finalResults.containsKey(audio.id))
        .toList();

    if (unmatchedAudios.isNotEmpty) {
      final bool shouldAutoShow = AppStorage.settingsBox.get(
        StorageKeys.autoManualLyricsMatch,
        defaultValue: false,
      ) as bool;

      if (shouldAutoShow && onShowManualMatchDialog != null) {
        // 传递完整数据源给 UI 层弹窗使用
        onShowManualMatchDialog(
          playList,
          lyricList,
          Map<String, FileNode>.from(finalResults),
        );
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
      // 比对 ID 确认是否需要覆盖写入
      if (cachedNode?.hash != lyricNode.hash) {
        entriesToUpdate[audioId] = lyricNode;
      }
    });

    if (entriesToUpdate.isNotEmpty) {
      box.putAll(entriesToUpdate);
    }
  }
}
/// 缓存匹配策略。
/// 优先读取本地持久化的匹配记录，跳过已匹配过的音频，避免重复计算。
/// 从独立的 Hive Box 中读取 [audio.id] 与 [FileNode] 的映射关系。
/// 验证缓存中的字幕文件是否仍然存在于当前的字幕列表中。
class CacheMatch extends MatchLyrics {

  Box<FileNode> get matchBox => AppStorage.lyricMatchBox;

  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    return playList.isNotEmpty && matchBox.isNotEmpty;
  }

  @override
  Map<String, FileNode> matchLyrics(
      List<MediaItem> playList,
      List<FileNode> lyricList, [
        Map<String, FileNode> currentMatches = const {}
      ]) {
    final results = <String, FileNode>{};

    for (var audio in playList) {
      if (currentMatches.containsKey(audio.id)) continue;

      final cachedLyricNode = matchBox.get(audio.id);
      if (cachedLyricNode != null) {
        results[audio.id] = cachedLyricNode;
      }
    }
    return results;
  }
}
/// 精确标题匹配策略。
///
/// **目的**: 找出音频与字幕标题完全一致的配对。
/// **机制**: 将字幕列表转换为哈希表（Hash Map），以字幕标题为键，从而将匹配的时间复杂度从 O(N*M) 降低到 O(N)。
/// 匹配时严格保证一对一关系，已被占用的字幕不会被重复分配。
/// **适用条件**: 音频列表和字幕列表均不为空即可启用。
class AccurateMatch extends MatchLyrics {
  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    return playList.isNotEmpty && lyricList.isNotEmpty;
  }

  @override
  Map<String, FileNode> matchLyrics(
      List<MediaItem> playList,
      List<FileNode> lyricList, [
        Map<String, FileNode>? currentMatches,
      ]) {
    final results = <String, FileNode>{};
    // 追踪“已经被分配给某首音频的字幕”，防止多个同名音频抢走同一个字幕
    final usedLyrics = currentMatches?.values.toSet() ?? <FileNode>{};

    final lyricMap = {
      for (var node in lyricList) node.title: node
    };

    for (var audio in playList) {
      // 守卫 1：跳过已匹配的音频
      if (currentMatches?.containsKey(audio.id) ?? false) continue;

      // 守卫 2：直接用 Title 查找，并且确保该字幕还未被占用
      if (lyricMap.containsKey(audio.title)) {
        final matchedLyric = lyricMap[audio.title]!;
        if (!usedLyrics.contains(matchedLyric)) {
          results[audio.id] = matchedLyric;
          usedLyrics.add(matchedLyric); // 在当前循环中标记为已使用
        }
      }
    }
    return results;
  }
}

/// 模糊相似度匹配策略。
///
/// **目的**: 处理因文件名带有冗余信息（如 "Song_Name_Lyric" vs "Song Name"）导致精确匹配失败的情况。
/// **机制**: 采用 Sørensen–Dice 系数算法，通过提取字符串的相邻双字符组合（Bigrams）来计算文本相似度。
/// 分数在 0.0 到 1.0 之间，若超过设定的 [threshold] 且为当前最高分，则认为匹配成功。
/// 为提高性能，在遍历前统一预计算所有可用字幕的 Bigrams 集合。
/// **适用条件**: 音频列表和字幕列表均不为空即可启用。
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
      List<FileNode> lyricList, [
        Map<String, FileNode>? currentMatches,
      ]) {
    final results = <String, FileNode>{};
    final usedLyrics = currentMatches?.values.toSet() ?? <FileNode>{};

    // 1. 过滤出还没匹配的音频
    final pendingAudio = playList.where((a) =>
    !(currentMatches?.containsKey(a.id) ?? false));

    // 2. 核心修复：只在“尚未被前面的音频或策略使用过”的字幕里进行搜索
    final availableLyrics = lyricList.where((l) => !usedLyrics.contains(l)).toList();

    // 3. 性能优化：预先计算所有未被使用的字幕的 Bigrams Set
    final lyricBigramsMap = <FileNode, Set<String>>{};
    for (var lyric in availableLyrics) {
      lyricBigramsMap[lyric] = _getBigrams(lyric.title);
    }

    for (var audio in pendingAudio) {
      FileNode? bestMatch;
      double highestScore = 0.0;

      // 计算当前音频的 Bigrams
      final audioBigrams = _getBigrams(audio.title);

      for (var lyric in availableLyrics) {
        // 核心修复：即使在前期的过滤中排除了，如果前面的循环刚用过这个字幕，也要跳过
        if (usedLyrics.contains(lyric)) continue;

        final lyricBigrams = lyricBigramsMap[lyric]!;
        final score = _calculateDiceCoefficient(s1Bigrams: audioBigrams, s2Bigrams: lyricBigrams);

        if (score > highestScore && score >= threshold) {
          highestScore = score;
          bestMatch = lyric;
        }
      }

      if (bestMatch != null) {
        results[audio.id] = bestMatch;
        usedLyrics.add(bestMatch); // 标记此字幕为已占用！
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
    final smallerSet = s1Bigrams.length < s2Bigrams.length ? s1Bigrams : s2Bigrams;
    final largerSet = s1Bigrams.length < s2Bigrams.length ? s2Bigrams : s1Bigrams;

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
    if (refined.length < 2) return {refined};

    for (int i = 0; i < refined.length - 1; i++) {
      bigrams.add(refined.substring(i, i + 2));
    }
    return bigrams;
  }
}

/// 序号提取匹配策略 (兜底策略)。
///
/// **目的**: 提取音频和字幕文件名中包含的数字序号（如 "01", "Track 2"）进行匹配。
/// **机制**: 利用正则表达式提取标题中出现的首组数字并转化为整型（抹平 "01" 与 "1" 的差异）。
/// 若未匹配音频和未使用字幕具有相同的序号，则进行绑定。
/// **适用条件**: 一轮匹配下来如果还有未匹配的音频，且未匹配的字幕不为空的话则进行序号强行绑定，后续提供手动匹配交给用户进行匹配
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
      List<FileNode> lyricList, [
        Map<String, FileNode>? currentMatches,
      ]) {
    final results = <String, FileNode>{};
    final usedLyrics = currentMatches?.values.toSet() ?? <FileNode>{};

    // 预处理尚未被使用的字幕，建立 [序号 -> 字幕节点] 的映射表
    final lyricSequenceMap = <int, FileNode>{};
    for (var lyric in lyricList) {
      if (usedLyrics.contains(lyric)) continue;

      final seq = _extractSequenceNumber(lyric.title);
      // 遇到重复的序号时，仅保留第一个遍历到的字幕，避免字典覆盖乱序
      if (seq != null && !lyricSequenceMap.containsKey(seq)) {
        lyricSequenceMap[seq] = lyric;
      }
    }

    if (lyricSequenceMap.isEmpty) return results;

    for (var audio in playList) {
      if (currentMatches?.containsKey(audio.id) ?? false) continue;

      final audioSeq = _extractSequenceNumber(audio.title);
      if (audioSeq != null && lyricSequenceMap.containsKey(audioSeq)) {
        final matchedLyric = lyricSequenceMap[audioSeq]!;

        if (!usedLyrics.contains(matchedLyric)) {
          results[audio.id] = matchedLyric;
          usedLyrics.add(matchedLyric);
        }
      }
    }

    return results;
  }
}