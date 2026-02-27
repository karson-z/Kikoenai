import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import '../../../features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import '../../enums/node_type.dart';
import 'package:path/path.dart' as p;

class LyricsDataProcess {
  /// 字幕文件名数据处理
  /// 输入[nodes] 字幕文件列表
  static List<FileNode> batchLyricsProcess(List<FileNode> nodes) {
    return nodes.map((node) {
      final cleanTitle = _generateFingerprint(node.title);
      // 返回带有新标题的新对象
      return node.copyWith(title: cleanTitle);
    }).toList();
  }
  /// 播放列表数据处理
  /// 输入[playList] 播放列表
  static List<MediaItem> batchPlayListProcess(List<MediaItem> playList) {
    return playList.map((mediaItem) {
      final cleanTitle = _generateFingerprint(mediaItem.title);
      // 返回带有新标题的新对象
      return mediaItem.copyWith(title: cleanTitle);
    }).toList();
  }
  /// [内部流水线] 生成文件指纹
  /// 将三个步骤串联：取文件名 -> 去扩展名 -> 去干扰字符 -> 归一化
  static String _generateFingerprint(String originalName) {
    String step1 = _removeAllExtensions(originalName);
    String step2 = _removeSuffixes(step1);
    String step3 = _normalizeForComparison(step2);
    return step3;
  }

  /// 1. 安全去除扩展名
  static String _removeAllExtensions(String fileName) {
    while (p.extension(fileName).isNotEmpty) {
      fileName = p.basenameWithoutExtension(fileName);
    }
    return fileName;
  }

  /// 2. 去除括号、特殊标签、特定后缀
  static String _removeSuffixes(String input) {
    var result = input;

    result =
        result.replaceAll(RegExp(r'(（.*?）|\(.*?\)|\[.*?\]|【.*?】|《.*?》)'), '');

    const suffixes = FileExtensions.seSuffixes; // 示例
    for (final suffix in suffixes) {
      if (result.toLowerCase().endsWith(suffix.toLowerCase())) {
        result = result.substring(0, result.length - suffix.length);
      }
    }
    return result.trim();
  }

  /// 3. 最终归一化 (转小写、合并空格)
  static String _normalizeForComparison(String input) {
    String text = input.toLowerCase();

    // 将常见的分隔符 (下划线、横杠、点) 替换为空格
    text = text.replaceAll(RegExp(r'[_\-.]'), ' ');

    // 将多个连续空格合并为一个，并去头尾
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

abstract class MatchLyrics {
  /// 检查该策略是否适用 (前置守卫)
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList);

  /// 执行匹配
  /// [currentMatches] : 上一轮策略已匹配的结果 (Key: audio.hash, Value: lyricNode)
  Map<String, FileNode> matchLyrics(
      List<MediaItem> playList,
      List<FileNode> lyricList, [
        Map<String, FileNode>? currentMatches,
      ]);

  /// 统一入口：按顺序执行策略链
  static Map<String, FileNode> match(
      List<MediaItem> playList,
      List<FileNode> lyricList, {
        List<MatchLyrics>? strategies,
      }) {
    // 默认执行顺序：精确 -> 模糊 -> 索引(兜底)
    final runStrategies = strategies ??
        [
          AccurateMatch(),
          FuzzyMatch(),
          IndexMatch(),
        ];

    final Map<String, FileNode> finalResults = {};

    for (final strategy in runStrategies) {
      if (strategy.isMatch(playList, lyricList)) {
        // 执行当前策略，传入已有的结果以避免重复计算
        var newMatches = strategy.matchLyrics(playList, lyricList, finalResults);

        // 合并结果
        newMatches.forEach((hashKey, lyricNode) {
          if (!finalResults.containsKey(hashKey)) {
            finalResults[hashKey] = lyricNode;
          }
        });
      }
    }
    return finalResults;
  }
}
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

    final lyricMap = {
      for (var node in lyricList) node.title: node
    };

    for (var audio in playList) {
      // 守卫：如果 hash 为空或已匹配，跳过
      if (currentMatches?.containsKey(audio.id) ?? false) continue;

      // 2. 直接用 Title 查找
      if (lyricMap.containsKey(audio.title)) {
        results[audio.id] = lyricMap[audio.title]!;
      }
    }
    return results;
  }
}
class FuzzyMatch extends MatchLyrics {
  final double threshold; // 推荐 0.4 ~ 0.7 之间，Dice 的容错率较高
  // 0.6 是一个比较安全的起始值

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

    // 1. 过滤出还没匹配的音频
    final pendingAudio = playList.where((a) =>
    !(currentMatches?.containsKey(a.id) ?? false)
    );

    // 2. 性能优化：预先计算所有字幕的 Bigrams Set
    // 避免在双重循环中重复计算，将复杂度从 O(N*M*L) 降低
    final lyricBigramsMap = <FileNode, Set<String>>{};
    for (var lyric in lyricList) {
      lyricBigramsMap[lyric] = _getBigrams(lyric.title);
    }

    for (var audio in pendingAudio) {
      FileNode? bestMatch;
      double highestScore = 0.0;

      // 计算当前音频的 Bigrams (只算一次)
      final audioBigrams = _getBigrams(audio.title);

      // 遍历所有字幕寻找最佳匹配
      for (var lyric in lyricList) {
        final lyricBigrams = lyricBigramsMap[lyric]!;

        final score = _calculateDiceCoefficient(
            audio.title,
            lyric.title,
            s1Bigrams: audioBigrams,
            s2Bigrams: lyricBigrams
        );

        if (score > highestScore && score >= threshold) {
          highestScore = score;
          bestMatch = lyric;
        }
      }

      if (bestMatch != null) {
        results[audio.id] = bestMatch;
      }
    }
    return results;
  }

  /// 核心算法：Sørensen–Dice Coefficient (Bigrams)
  /// 为了性能优化，我稍微修改了参数，允许直接传入预计算好的 Set
  double _calculateDiceCoefficient(
      String s1,
      String s2, {
        Set<String>? s1Bigrams,
        Set<String>? s2Bigrams
      }) {
    // 快速路径：完全相等
    if (s1 == s2) return 1.0;
    // 快速路径：去空格后相等
    if (s1.replaceAll(' ', '') == s2.replaceAll(' ', '')) return 1.0;

    // 如果没传 Set，就现场计算
    final set1 = s1Bigrams ?? _getBigrams(s1);
    final set2 = s2Bigrams ?? _getBigrams(s2);

    if (set1.isEmpty || set2.isEmpty) return 0.0;

    int intersection = 0;
    // 优化：总是遍历较小的那个 Set 来计算交集，速度更快
    final smallerSet = set1.length < set2.length ? set1 : set2;
    final largerSet = set1.length < set2.length ? set2 : set1;

    for (var item in smallerSet) {
      if (largerSet.contains(item)) {
        intersection++;
      }
    }

    return (2.0 * intersection) / (set1.length + set2.length);
  }

  /// 生成字符双元组 (Bigrams)
  Set<String> _getBigrams(String input) {
    Set<String> bigrams = {};
    // 为了更准确匹配，通常计算 Bigram 时去除所有空格
    String refined = input.replaceAll(' ', '');

    // 边界处理：如果字符串太短，直接把整个字符串作为一个特征
    if (refined.length < 2) return {refined};

    for (int i = 0; i < refined.length - 1; i++) {
      bigrams.add(refined.substring(i, i + 2));
    }
    return bigrams;
  }
}

class IndexMatch extends MatchLyrics {
  @override
  bool isMatch(List<MediaItem> playList, List<FileNode> lyricList) {
    // 只有当数量严格一致时才启用，防止错位太离谱
    return playList.length == lyricList.length;
  }

  @override
  Map<String, FileNode> matchLyrics(
      List<MediaItem> playList,
      List<FileNode> lyricList, [
        Map<String, FileNode>? currentMatches,
      ]) {
    final results = <String, FileNode>{};

    // 必须先排序
    final sortedAudio = List<FileNode>.from(playList)
      ..sort((a, b) => a.title.compareTo(b.title));

    final sortedLyric = List<FileNode>.from(lyricList)
      ..sort((a, b) => a.title.compareTo(b.title));

    for (int i = 0; i < sortedAudio.length; i++) {
      final audio = sortedAudio[i];
      final lyric = sortedLyric[i];

      // 只有没匹配过的才强行配对
      if (audio.hash != null &&
          !(currentMatches?.containsKey(audio.hash) ?? false)) {
        results[audio.hash!] = lyric;
      }
    }
    return results;
  }
}

class SearchLyricsService {
  /// 找出当前作品下的所有字幕文件。
  static List<FileNode> findSubTitlesInFiles(List<FileNode> files) {
    final List<FileNode> result = [];
    const allowedExtensions = FileExtensions.subtitles;

    for (var file in files) {
      if (file.isFolder && file.children != null) {
        result.addAll(findSubTitlesInFiles(file.children!));
      } else {
        final fileName = file.title.toLowerCase();

        bool isSubtitle =
            allowedExtensions.any((ext) => fileName.endsWith('$ext'));

        if (isSubtitle) {
          result.add(file);
        }
      }
    }
    return result;
  }

  /// 查找文件树中是否有该作品的字幕
  /// [nodes] 本地文件树节点
  /// [workId] 作品ID
  static FileNode? findNodeInTree(List<FileNode> nodes, String workId) {
    if (workId.isEmpty) return null;
    final inputRaw = workId.trim().toLowerCase();
    final inputNumeric = inputRaw.replaceAll(RegExp(r'[^0-9]'), '');

    for (final node in nodes) {
      // 1. 检查当前节点是否匹配 (逻辑同之前的 matchTarget)
      // 注意：只匹配文件夹或压缩包类型的节点 (通常都有 children)
      if (node.isFolder || node.children != null && node.children!.isNotEmpty) {
        final folderName = node.title.toLowerCase();
        bool isMatch = false;

        // 匹配逻辑: 包含原始ID 或 包含纯数字ID
        if (folderName.contains(inputRaw)) {
          isMatch = true;
        } else if (inputNumeric.isNotEmpty &&
            folderName.contains(inputNumeric)) {
          // 短数字保护
          if (inputNumeric.length < 3) {
            if (folderName == inputNumeric) isMatch = true;
          } else {
            isMatch = true;
          }
        }

        if (isMatch) return node; // 找到了！
      }

      // 2. 没匹配上，且有子节点，继续递归查找子节点
      if (node.children != null && node.children!.isNotEmpty) {
        final result = findNodeInTree(node.children!, workId);
        if (result != null) return result;
      }
    }
    return null;
  }

  static List<FileNode> flattenSubtitles(FileNode targetNode) {
    List<FileNode> results = [];
    // 辅助递归函数
    void traverse(FileNode node) {
      if (node.isFolder ||
          (node.children != null && node.children!.isNotEmpty)) {
        // 如果是文件夹/压缩包，继续深入
        node.children?.forEach(traverse);
      } else {
        if (node.type == NodeType.text) {
          results.add(node);
        }
      }
    }

    traverse(targetNode);
    return results;
  }
  /// 获取本地字幕
  /// [workId] 作品Id
  // static List<FileNode> findSubtitleInLocalById(String workId) {
  //   // --- 开始树查找逻辑 ---
  //   List<FileNode> targetSubtitleList = [];
  //   try {
  //     // A. 获取缓存树
  //     final subTitleFiles =
  //         CacheService.instance.getCachedScanResults(mode: ScanMode.subtitles);
  //     final paths =
  //         CacheService.instance.getScanRootPaths(mode: ScanMode.subtitles);
  //     final fileTree = MediaTreeBuilder.build(subTitleFiles, paths);
  //
  //     // B. 在树中查找目标 Work 节点
  //     final targetNode = SearchLyricsService.findNodeInTree(fileTree, workId);
  //
  //     if (targetNode != null) {
  //       debugPrint("命中树节点: ${targetNode.title}");
  //       // C. 提取该节点下的所有字幕
  //       targetSubtitleList = SearchLyricsService.flattenSubtitles(targetNode);
  //     } else {
  //       debugPrint("未在缓存树中找到 ID: $workId 的对应文件");
  //       targetSubtitleList = []; // 没找到则置空，防止残留上一个作品的字幕
  //     }
  //   } catch (e) {
  //     debugPrint("字幕树查找失败: $e");
  //     targetSubtitleList = [];
  //   }
  //   return targetSubtitleList;
  // }

  /// 获取网络的文件列表
  /// [workId] 作品Id
  /// [ref] ProviderRef
  static Future<List<FileNode>> findSubtitleInNetWorkById(
      String workId, Ref ref) async {
    // A.拿到作品对应的文件列表
    final workFiles =
        await ref.read(trackFileNodeProvider(int.parse(workId)).future);
    final subTitleFiles = SearchLyricsService.findSubTitlesInFiles(workFiles);
    return subTitleFiles;
  }
}
