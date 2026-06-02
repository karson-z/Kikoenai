import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/core/service/file/scan_mode.dart';
import '../../../features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import 'package:path/path.dart' as p;

import '../file/file_scanner_storage.dart';

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
  static List<FileNode> findSubTitlesInFiles(List<FileNode> files) {
    final List<FileNode> result = [];
    const allowedExtensions = FileExtensions.subtitles;

    for (var file in files) {
      if (file.isFolder && file.children != null) {
        result.addAll(findSubTitlesInFiles(file.children!));
      } else {
        final fileName = file.title.toLowerCase();

        bool isSubtitle = allowedExtensions.any(
          (ext) => fileName.endsWith(ext),
        );

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
    int workId,
    Ref ref,
  ) async {
    // A.拿到作品对应的文件列表
    final workFiles = await ref.read(trackFileNodeProvider(workId).future);
    final subTitleFiles = SearchLyricsService.findSubTitlesInFiles(workFiles);
    return subTitleFiles;
  }

  /// 查找当前作品下的所有字幕
  /// [workId] 作品Id
  /// [ref] ProviderRef
  static Future<List<FileNode>> findLyrics(int workId, Ref ref) async {
    final localLyrics = findSubtitleInLocalById(workId);
    if (localLyrics.isNotEmpty) {
      return localLyrics;
    }
    final netWorkLyrics = await findSubtitleInNetWorkById(workId, ref);
    return netWorkLyrics;
  }
}
