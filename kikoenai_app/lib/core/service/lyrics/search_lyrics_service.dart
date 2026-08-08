import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../features/album/provider/audio_file_provider.dart';
import 'package:path/path.dart' as p;

import '../file/file_scanner_storage.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';

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

    result = result.replaceAll(
      RegExp(r'(（.*?）|\(.*?\)|\[.*?\]|【.*?】|《.*?》)'),
      '',
    );

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

class SearchLyricsService {
  /// 找出当前作品下的所有字幕文件。
  static List<FileNode> findSubTitlesInFiles(FileNodeLibraryIndex files) {
    return files.collectAllSubtitles();
  }

  static List<FileNode> findSubtitleInLocalById(int workId) {
    final subtitles = FileScannerStorage()
        .getAllByMode(ScanMode.subtitles)
        .where((node) => !node.isFolder && node.workId == workId)
        .toList();

    subtitles.sort((a, b) {
      final pathA = a.effectivePath.toLowerCase();
      final pathB = b.effectivePath.toLowerCase();
      return pathA.compareTo(pathB);
    });

    return subtitles;
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
    SiteContentId contentId,
    Ref ref,
  ) async {
    // A.拿到作品对应的文件列表
    final workFiles = await ref.read(trackFileNodeIndexProvider(contentId).future);
    final subTitleFiles = SearchLyricsService.findSubTitlesInFiles(workFiles);
    return subTitleFiles;
  }

  /// 查找当前作品下的所有字幕
  /// [workId] 作品Id
  /// [ref] ProviderRef
  static Future<List<FileNode>> findLyrics(
    int workId,
    Ref ref, {
    SiteContentId? contentId,
  }) async {
    final localLyrics = findSubtitleInLocalById(workId);
    if (localLyrics.isNotEmpty) {
      return localLyrics;
    }
    if (contentId == null) return const [];
    final netWorkLyrics = await findSubtitleInNetWorkById(contentId, ref);
    return netWorkLyrics;
  }
}
