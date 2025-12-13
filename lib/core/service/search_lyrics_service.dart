import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart';
class SearchLyricsService {

  // --- 你现有的代码 (保持不变) ---

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

  /// 内部标准化方法：用于最终比对前的清洗
  /// 这一步非常关键，它消除 "Song_Name" 和 "Song Name" 之间的差异
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
}