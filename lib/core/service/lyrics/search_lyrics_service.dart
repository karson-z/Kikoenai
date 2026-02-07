import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
import '../../../features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import '../../../features/local_media/data/service/tree_service.dart';
import '../cache/cache_service.dart';
import '../file/file_scanner_service.dart';
class SearchLyricsService {
  /// 去除文件扩展名
  static String removeExtension(String fileName, Set<String> extensions) {
    final lowerName = fileName.toLowerCase();
    for (final ext in extensions) {
      if (lowerName.endsWith(ext)) {
        return fileName.substring(0, fileName.length - ext.length);
      }
    }
    return fileName;
  }

  /// 去除字幕文件后缀特殊字幕等
  static String removeSuffixes(String fileName) {
    var result = fileName;

    // 1. 去除括号及其内容
    result = result.replaceAll(RegExp(r'（.*?）'), '');
    result = result.replaceAll(RegExp(r'\(.*?\)'), '');
    result = result.replaceAll(RegExp(r'\[.*?\]'), '');
    result = result.replaceAll(RegExp(r'【.*?】'), '');
    result = result.replaceAll(RegExp(r'《.*?》'), '');

    // 2. 去除特定的 SE 后缀
    for (final suffix in FileExtensions.seSuffixes) {
      if (result.toLowerCase().endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length);
      }
    }
    return result.trim();
  }
  /// 找出当前作品下的所有字幕文件。
  static List<FileNode> findSubTitlesInFiles(List<FileNode> files) {
    final List<FileNode> result = [];
    const allowedExtensions = FileExtensions.subtitles;

    for (var file in files) {
      if (file.isFolder && file.children != null) {
        result.addAll(findSubTitlesInFiles(file.children!));
      } else {
        final fileName = file.title.toLowerCase();

        bool isSubtitle = allowedExtensions.any((ext) => fileName.endsWith('$ext'));

        if (isSubtitle) {
          result.add(file);
        }
      }
    }
    return result;
  }
  // --- 新增的核心匹配逻辑 ---

  /// 寻找最佳匹配字幕
  /// [currentSongName]: 当前播放的歌曲文件名 (带后缀)
  /// [subtitleFiles]: 字幕文件列表 (带后缀)
  /// [threshold]: 匹配阈值 (0.0 - 1.0)
  static String? findBestMatch(
      String currentSongName,
      List<String> subtitleFiles, {
        double threshold = 0.4,
      }) {
    if (subtitleFiles.isEmpty) return null;

    // 1. 处理源文件名：去后缀 -> 去噪音 -> 标准化
    String cleanSong = removeExtension(currentSongName, FileExtensions.audio);
    cleanSong = removeSuffixes(cleanSong);
    final normalizedSong = _normalizeForComparison(cleanSong);

    String? bestMatchFile;
    double maxScore = -1.0;

    for (var subFile in subtitleFiles) {
      // 2. 处理候选文件名
      String cleanSub = removeExtension(subFile, FileExtensions.subtitles);
      String cleanExt = removeExtension(cleanSub, FileExtensions.audio);
      cleanExt = removeSuffixes(cleanExt);
      final normalizedSub = _normalizeForComparison(cleanExt);
      // 3. 计算相似度
      double score = _calculateDiceCoefficient(normalizedSong, normalizedSub);
      // 4. 包含关系加分 (Heuristic)
      // 如果去噪后的文件名存在包含关系 (例如 "Song" 和 "Artist - Song")，给予加分
      if (normalizedSong.contains(normalizedSub) || normalizedSub.contains(normalizedSong)) {
        score += 0.25;
        if (score > 1.0) score = 1.0;
      }
      print('Song: $normalizedSong | Sub: $normalizedSub | Score: $score');
      if (score > maxScore) {
        maxScore = score;
        bestMatchFile = subFile;
      }
    }
    return maxScore >= threshold ? bestMatchFile : null;
  }
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
        } else if (inputNumeric.isNotEmpty && folderName.contains(inputNumeric)) {
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

// --- 工具方法 B: 将目标节点下的所有字幕文件“拍扁” ---
 static List<FileNode> flattenSubtitles(FileNode targetNode) {
    List<FileNode> results = [];

    // 辅助递归函数
    void traverse(FileNode node) {
      if (node.isFolder || (node.children != null && node.children!.isNotEmpty)) {
        // 如果是文件夹/压缩包，继续深入
        node.children?.forEach(traverse);
      } else {
        // 如果是文件，直接加入结果
        // 这里可以加个双重保险，判断一下是否是字幕类型
        // if (node.type == NodeType.text || node.type == NodeType.subtitle)
        results.add(node);
      }
    }

    traverse(targetNode);
    return results;
  }
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
  static List<FileNode> findSubtitleInLocalById(String workId){
    // --- 开始树查找逻辑 ---
    List<FileNode> targetSubtitleList = [];
    try {
      // A. 获取缓存树
      final subTitleFiles = CacheService.instance.getCachedScanResults(mode: ScanMode.subtitles);
      final paths = CacheService.instance.getScanRootPaths(mode: ScanMode.subtitles);
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
  static Future<List<FileNode>> findSubtitleInNetWorkById(String workId,Ref ref) async {
    // A.拿到作品对应的文件列表
    final workFiles = await ref.read(trackFileNodeProvider(int.parse(workId)).future);
    final subTitleFiles = SearchLyricsService.findSubTitlesInFiles(workFiles);
    return subTitleFiles;
  }
}