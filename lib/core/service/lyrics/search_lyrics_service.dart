import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import '../../../features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import '../../../features/local_media/data/service/tree_service.dart';
import '../../enums/node_type.dart';
import '../cache/cache_service.dart';
import '../file/file_scanner_service.dart';
import 'package:path/path.dart' as p;

class LyricsDataProcess {
  /// 文件名数据处理
  /// 输入[nodes] 音频文件列表 或 字幕文件列表
  static List<FileNode> batchProcess(List<FileNode> nodes) {
    return nodes.map((node) {
      final cleanTitle = _generateFingerprint(node.title);
      // 返回带有新标题的新对象
      return node.copyWith(title: cleanTitle);
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
        result.replaceAll(RegExp(r'(\（.*?\）|\(.*?\)|\[.*?\]|【.*?】|《.*?》)'), '');

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

  bool isMatch(List<FileNode> playList, List<FileNode> lyricList);

  // 匹配字幕列表
  static Map<String, FileNode> match(
      List<FileNode> playList, List<FileNode> lyricList,
      {List<MatchLyrics>? match}) {
    return (match ?? [])
        .firstWhere((m) => m.isMatch(playList, lyricList))
        .matchLyrics(playList, lyricList);
  }

  Map<String, FileNode> matchLyrics(
      List<FileNode> playList, List<FileNode> lyricList);
}
class accurateMatch extends MatchLyrics {
  @override
  bool isMatch(List<FileNode> playList, List<FileNode> lyricList) {
    // TODO: implement isMatch
    throw UnimplementedError();
  }

  @override
  Map<String, FileNode> matchLyrics(List<FileNode> playList, List<FileNode> lyricList) {
    // TODO: implement matchLyrics
    throw UnimplementedError();
  }

}
class fuzzyMatch extends MatchLyrics {
  @override
  bool isMatch(List<FileNode> playList, List<FileNode> lyricList) {
    // TODO: implement isMatch
    throw UnimplementedError();
  }

  @override
  Map<String, FileNode> matchLyrics(List<FileNode> playList, List<FileNode> lyricList) {
    // TODO: implement matchLyrics
    throw UnimplementedError();
  }

}
class indexMatch extends MatchLyrics {
  @override
  bool isMatch(List<FileNode> playList, List<FileNode> lyricList) {
    // TODO: implement isMatch
    throw UnimplementedError();
  }

  @override
  Map<String, FileNode> matchLyrics(List<FileNode> playList, List<FileNode> lyricList) {
    // TODO: implement matchLyrics
    throw UnimplementedError();
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

  // 匹配逻辑
  static String _normalizeForComparison(String input) {
    String text = input.toLowerCase();

    // 将常见的分隔符 (下划线、横杠、点) 替换为空格
    text = text.replaceAll(RegExp(r'[_\-.]'), ' ');

    // 将多个连续空格合并为一个，并去头尾
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 核心算法：Sørensen–Dice Coefficient (Bigrams)
  /// 相比编辑距离，它对语序颠倒（歌手-歌名 vs 歌名-歌手）有更好的容错性
  static double _calculateDiceCoefficient(String s1, String s2) {
    if (s1 == s2) return 1.0;
    // 如果去掉空格后完全一样，直接返回 1.0
    if (s1.replaceAll(' ', '') == s2.replaceAll(' ', '')) return 1.0;

    Set<String> s1Bigrams = _getBigrams(s1);
    Set<String> s2Bigrams = _getBigrams(s2);

    if (s1Bigrams.isEmpty || s2Bigrams.isEmpty) return 0.0;

    int intersection = 0;
    for (var item in s1Bigrams) {
      if (s2Bigrams.contains(item)) {
        intersection++;
      }
    }

    return (2.0 * intersection) / (s1Bigrams.length + s2Bigrams.length);
  }

  /// 生成字符双元组 (Bigrams)
  static Set<String> _getBigrams(String input) {
    Set<String> bigrams = {};
    // 为了更准确匹配，通常计算 Bigram 时去除所有空格
    String refined = input.replaceAll(' ', '');
    if (refined.length < 2) return {refined}; // 处理单字情况

    for (int i = 0; i < refined.length - 1; i++) {
      bigrams.add(refined.substring(i, i + 2));
    }
    return bigrams;
  }

  /// 获取本地字幕
  /// [workId] 作品Id
  static List<FileNode> findSubtitleInLocalById(String workId) {
    // --- 开始树查找逻辑 ---
    List<FileNode> targetSubtitleList = [];
    try {
      // A. 获取缓存树
      final subTitleFiles =
          CacheService.instance.getCachedScanResults(mode: ScanMode.subtitles);
      final paths =
          CacheService.instance.getScanRootPaths(mode: ScanMode.subtitles);
      final fileTree = MediaTreeBuilder.build(subTitleFiles, paths);

      // B. 在树中查找目标 Work 节点
      final targetNode = SearchLyricsService.findNodeInTree(fileTree, workId);

      if (targetNode != null) {
        debugPrint("命中树节点: ${targetNode.title}");
        // C. 提取该节点下的所有字幕
        targetSubtitleList = SearchLyricsService.flattenSubtitles(targetNode);
      } else {
        debugPrint("未在缓存树中找到 ID: $workId 的对应文件");
        targetSubtitleList = []; // 没找到则置空，防止残留上一个作品的字幕
      }
    } catch (e) {
      debugPrint("字幕树查找失败: $e");
      targetSubtitleList = [];
    }
    return targetSubtitleList;
  }

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
