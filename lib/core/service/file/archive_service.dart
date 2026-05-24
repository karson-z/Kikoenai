import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
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

  /// 1. 扫描压缩包
  /// 【修改注意】：因为解码变成了异步，这里也必须变成 Future 异步方法
  static Future<List<ArchiveEntry>> scanZip(File file, {Set<String>? allowedExts}) async {
    List<ArchiveEntry> results = [];
    final filePath = file.path;

    InputFileStream? inputStream;
    try {
      inputStream = InputFileStream(filePath);
      final archive = ZipDecoder().decodeStream(inputStream);

      for (final fileHeader in archive.files) {
        if (!fileHeader.isFile) continue;
        if (fileHeader.name.startsWith('__MACOSX')) continue;
        if (fileHeader.name.startsWith('.')) continue;

        // 【关键修复】：添加 await 等待异步解码完成
        final internalPath = await CharsetCover.fixEncoding(fileHeader.name);

        // 后缀检查
        if (allowedExts != null) {
          if (!internalPath.contains('.')) continue;
          final ext = internalPath.substring(internalPath.lastIndexOf('.')).toLowerCase();
          if (!allowedExts.contains(ext)) continue;
        }

        // 使用 '/' 连接
        final cleanInternalPath = internalPath.replaceAll('\\', '/');
        // 保证不出现双斜杠
        final formattedInternal = cleanInternalPath.startsWith('/')
            ? cleanInternalPath.substring(1)
            : cleanInternalPath;

        final virtualPath = "$filePath/$formattedInternal";

        results.add(ArchiveEntry(
          virtualPath: virtualPath,
          name: formattedInternal.split('/').last,
          size: fileHeader.size,
        ));
      }
    } catch (e) {
      debugPrint("ArchiveService: 扫描失败 $filePath, $e");
    } finally {
      // 确保流被关闭，防止内存泄漏或文件占用
      inputStream?.close();
    }
    return results;
  }

  /// 2. 读取文件
  static Future<Uint8List?> extractFile(String virtualPath) async {
    String zipPath = "";
    String internalPath = "";

    // 【性能优化】: O(1) 的字符串切分，替代原本缓慢的同步文件系统 I/O 遍历
    final lowerPath = virtualPath.toLowerCase();
    int splitIndex = -1;

    for (final ext in supportedExts) {
      // 寻找类似 ".zip/" 或 ".cbz/" 的分界点
      final searchStr = "$ext/";
      final index = lowerPath.indexOf(searchStr);
      if (index != -1) {
        splitIndex = index + ext.length; // 定位到扩展名结束的位置
        break;
      }
    }

    if (splitIndex != -1) {
      zipPath = virtualPath.substring(0, splitIndex);
      internalPath = virtualPath.substring(splitIndex + 1); // 跳过斜杠
    } else {
      return null;
    }

    // --- 开始解压 ---
    InputFileStream? inputStream;
    try {
      inputStream = InputFileStream(zipPath);
      // 使用 decodeStream 避免一次性把整个压缩包载入内存
      final archive = ZipDecoder().decodeStream(inputStream);

      ArchiveFile? targetFile;

      for (final file in archive.files) {
        // 【关键修复】：这里同样需要 await，拿到实际字符串后再进行 replaceAll
        final decodedName = await CharsetCover.fixEncoding(file.name);
        final fixedName = decodedName.replaceAll('\\', '/');

        final cleanFixedName = fixedName.startsWith('/') ? fixedName.substring(1) : fixedName;

        if (cleanFixedName == internalPath) {
          targetFile = file;
          break;
        }
      }

      if (targetFile != null) {
        // file.content getter 会触发内部的解压逻辑 (Inflate)
        final content = targetFile.content as List<int>;
        return content is Uint8List ? content : Uint8List.fromList(content);
      }
    } catch (e) {
      debugPrint("ArchiveService: 解压失败 $e");
    } finally {
      inputStream?.close();
    }
    return null;
  }

  /// 3. 提取文本
  static Future<String?> extractText(String virtualPath) async {
    final bytes = await extractFile(virtualPath);
    if (bytes == null) return null;

    // 【关键修复】：decodeBytes 已经是 Future，需要 await 等待解码完成，才能提取 .content
    final result = await FileEncodingHelper.decodeBytes(bytes.toList());
    return result.content;
  }
}