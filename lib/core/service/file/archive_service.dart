import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import '../../model/archive_entry.dart';
import '../../utils/data/charset_cover.dart';

class ArchiveService {
  // 支持的后缀
  static const Set<String> supportedExts = {'.zip', '.cbz'};

  static bool isArchive(String path) {
    if (!path.contains('.')) return false;
    final ext = path.substring(path.lastIndexOf('.')).toLowerCase();
    return supportedExts.contains(ext);
  }

  /// 1. 扫描压缩包 (修改：生成看起来像目录的路径)
  static List<ArchiveEntry> scanZip(File file, {Set<String>? allowedExts}) {
    List<ArchiveEntry> results = [];
    final filePath = file.path; // 例如 /data/user/0/subs.zip

    try {
      final inputStream = InputFileStream(filePath);
      final archive = ZipDecoder().decodeStream(inputStream);

      for (final fileHeader in archive.files) {
        if (!fileHeader.isFile) continue;
        if (fileHeader.name.startsWith('__MACOSX')) continue;
        if (fileHeader.name.startsWith('.')) continue;
        // 修复编码问题，统一字符编码
        final internalPath = CharsetCover.fixEncoding(fileHeader.name); // 例如 sub/eng.srt

        // 后缀检查
        if (allowedExts != null) {
          if (!internalPath.contains('.')) continue;
          final ext = internalPath.substring(internalPath.lastIndexOf('.')).toLowerCase();
          if (!allowedExts.contains(ext)) continue;
        }

        //  使用 '/' 连接，让 TreeBuilder 认为 zip 是个文件夹
        // 注意：要确保 internalPath 不以 / 开头，避免双斜杠
        final cleanInternalPath = internalPath.replaceAll('\\', '/');
        final virtualPath = "$filePath/$cleanInternalPath";

        results.add(ArchiveEntry(
          virtualPath: virtualPath,
          name: cleanInternalPath.split('/').last,
          size: fileHeader.size,
        ));
      }
      inputStream.close();
    } catch (e) {
      debugPrint("ArchiveService: 扫描失败 $filePath, $e");
    }
    return results;
  }

  /// 2. 读取文件
  /// 因为现在路径里全是 '/'，我们需要判断哪一部分是本地存在的实体 Zip 文件
  static Future<Uint8List?> extractFile(String virtualPath) async {
    // 算法：逐级拆解路径，检查文件系统中是否存在该文件
    // 比如路径: /A/B/subs.zip/folder/file.srt
    // 检查 /A (Dir) -> /A/B (Dir) -> /A/B/subs.zip (File! 找到了)

    String zipPath = "";
    String internalPath = "";


    final parts = p.split(virtualPath); // 使用 path 包分割更安全
    String currentPath = parts[0];

    // 从根开始重建路径寻找 zip 文件
    for (int i = 1; i < parts.length; i++) {
      // 这里的 path separator 需要根据平台处理，Flutter p.join 会处理
      currentPath = p.join(currentPath, parts[i]);

      // 检查当前重建的路径是否是一个存在的实体文件
      if (File(currentPath).existsSync()) {
        if (isArchive(currentPath)) {
          zipPath = currentPath;
          // 剩下的部分就是内部路径
          internalPath = parts.sublist(i + 1).join('/');
          break;
        }
      }
    }

    if (zipPath.isEmpty || internalPath.isEmpty) return null;

    // --- 开始解压 ---
    InputFileStream? inputStream;
    try {
      inputStream = InputFileStream(zipPath);
      final archive = ZipDecoder().decodeStream(inputStream);
      final targetFile = archive.findFile(internalPath);

      if (targetFile != null) {
        final content = targetFile.content;
        return content;
      }
    } catch (e) {
      debugPrint("ArchiveService: 解压失败 $e");
    } finally {
      inputStream?.close();
    }
    return null;
  }

  static Future<String?> extractText(String virtualPath) async {
    final bytes = await extractFile(virtualPath);
    if (bytes == null) return null;
    return FileEncodingHelper.decodeBytes(bytes).content;
  }
}