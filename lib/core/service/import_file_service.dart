import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

// 引入你的工具类 (根据实际情况调整引用)
import 'package:kikoenai/core/utils/data/charset_cover.dart';

import '../common/global_exception.dart';

/// 文件类型枚举
enum ImportFileType { folder, singleFile, multipleFiles, archive, unknown }

class FileImportService {
  // --- 单例模式 ---
  static final FileImportService _instance = FileImportService._internal();
  factory FileImportService() => _instance;
  FileImportService._internal();

  /// 权限检查
  Future<bool> requestPermissions() async {
    // 1. 桌面端直接返回 true
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // 2. 判断 Android 版本
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13 (API 33) 及以上：必须请求 audio 权限
        // 对应 Manifest 里的 READ_MEDIA_AUDIO
        return (await Permission.audio.request()).isGranted;

      } else {
        // Android 12 及以下：请求 storage 权限
        // 对应 Manifest 里的 READ_EXTERNAL_STORAGE
        return (await Permission.storage.request()).isGranted;
      }
    }

    // iOS 逻辑
    if (Platform.isIOS) {
      return (await Permission.mediaLibrary.request()).isGranted;
    }

    return false;
  }

  /// 识别导入类型
  ImportFileType identifyImportType(List<String> paths) {
    if (paths.isEmpty) return ImportFileType.unknown;
    if (paths.length > 1) return ImportFileType.multipleFiles;

    final path = paths.first;
    final type = FileSystemEntity.typeSync(path);

    if (type == FileSystemEntityType.directory) {
      return ImportFileType.folder;
    } else if (type == FileSystemEntityType.file) {
      final ext = p.extension(path).toLowerCase();
      if (FileExtensions.archives.contains(ext)) {
        return ImportFileType.archive;
      }
      return ImportFileType.singleFile;
    }
    return ImportFileType.unknown;
  }

  /// 检查文件大小
  Future<bool> checkFileSize(List<String> paths, {int threshold = 2 * 1024 * 1024 * 1024}) async {
    int totalSize = 0;
    for (var path in paths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        try {
          final dir = Directory(path);
          await for (var entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) totalSize += await entity.length();
          }
        } catch (e) { return false; }
      } else {
        totalSize += await File(path).length();
      }
    }
    return totalSize <= threshold;
  }

  ///  当有[idRegexPattern]路径的时候，以其匹配到的名字作为归档文件名，当匹配不到时，使用当前日期进行归档
  ///  当没有[idRegexPattern] 正则的时候，单文件/多文件/压缩包（提取出来的符合要求的文件列表）/进行按日期归档，文件夹不进行任何处理，直接移动当前文件。
  String generateTargetPath(
      String firstPath,
      String rootTargetDir,
      ImportFileType type, {
        String? idRegexPattern,
      }) {
    // 1. 优先处理单文件/多文件
    if (type == ImportFileType.singleFile || type == ImportFileType.multipleFiles) {
      if (idRegexPattern != null && idRegexPattern.isNotEmpty) {
        try {
          final regExp = RegExp(idRegexPattern, caseSensitive: false);

          // A. 检查【目标根目录】的名字是否已经是 ID
          // 场景：用户已经进入了 /storage/emulated/0/Comics/RJ123456 目录
          final rootDirName = p.basename(rootTargetDir);
          if (regExp.hasMatch(rootDirName)) {
            return rootTargetDir;
          }

          // B. 【新增逻辑】检查【源文件名】是否包含 ID
          // 场景：导入 /Download/RJ123456.mp4 -> 自动创建 /Target/RJ123456 文件夹
          final sourceFileName = p.basename(firstPath);
          final match = regExp.firstMatch(sourceFileName);

          if (match != null) {
            // 提取匹配到的 ID (例如 RJ123456)
            final matchedId = match.group(0)!;
            // 返回拼接后的新路径: /Target/RJ123456
            return p.join(rootTargetDir, matchedId);
          }

        } catch (e) {
          print("⚠️ 正则匹配路径出错: $e");
        }
      }

      // C. 【兜底逻辑】如果都没匹配上，使用日期归档
      final now = DateTime.now();
      String dateFolderName = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      return p.join(rootTargetDir, dateFolderName);
    }

    // 2. 下面处理文件夹
    String folderName = p.basenameWithoutExtension(firstPath);

    if (idRegexPattern != null && idRegexPattern.isNotEmpty) {
      try {
        final regExp = RegExp(idRegexPattern, caseSensitive: false);
        final match = regExp.firstMatch(folderName);
        if (match != null) {
          return p.join(rootTargetDir, match.group(0)!);
        }
      } catch (e) {
        print("⚠️ 正则表达式错误: $e");
      }
    }

    // 3. 如果没传正则，或者正则没匹配到，使用原始文件夹名/压缩包名
    return p.join(rootTargetDir, folderName);
  }
  /// 执行导入
  Future<void> importFile({
    required List<String> sourcePaths,
    required String destinationPath,
    required ImportFileType type,
    required Set<String> allowedExtensions,
    Set<String>? excludedPatterns,
    String? idRegexPattern,
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    RegExp? idRegExp;
    if (idRegexPattern != null && idRegexPattern.isNotEmpty) {
      idRegExp = RegExp(idRegexPattern, caseSensitive: false);
    }

    final String rootStorageDir = Directory(destinationPath).parent.path;

    // 预判断：压缩包本身是否命中 ID
    bool initialParentMatched = false;
    if (idRegExp != null && sourcePaths.isNotEmpty) {
      final rootFileName = p.basename(sourcePaths.first);
      if (idRegExp.hasMatch(rootFileName)) {
        initialParentMatched = true;
      }
    }

    // 根据类型分发处理
    switch (type) {
      case ImportFileType.folder:
      // 改为 _moveDirectory
        await _moveDirectory(
            sourcePaths.first, destinationPath, rootStorageDir, allowedExtensions, excludedPatterns, idRegExp, onProgress);
        break;
      case ImportFileType.archive:
      // 改为 _extractAndConsumeArchive (解压并吞噬/删除源文件)
        await _extractAndConsumeArchive(
            sourcePaths.first, destinationPath, rootStorageDir, allowedExtensions, excludedPatterns, idRegExp, onProgress,
            parentMatched: initialParentMatched);
        break;
      case ImportFileType.singleFile:
      case ImportFileType.multipleFiles:
      // 改为 _moveMultipleFiles
        await _moveMultipleFiles(sourcePaths, destinationPath, allowedExtensions, excludedPatterns, onProgress);
        break;
      default:
        break;
    }
  }

  Future<void> _moveMultipleFiles(
      List<String> files,
      String dstDir,
      Set<String> allowedExts,
      Set<String>? excludes,
      Function(double, String)? onProgress) async {

    await Directory(dstDir).create(recursive: true);

    int total = files.length;
    int count = 0;

    for (var srcPath in files) {
      // 无论是否是目标文件，最后都要计算进度，否则进度条会卡住
      if (_isTargetFile(srcPath, allowedExts, excludes)) {
        final file = File(srcPath);
        final String newPath = p.join(dstDir, p.basename(srcPath));

        // ✅ 使用安全移动逻辑
        await _safeMoveFile(file, newPath);
      }

      // 更新进度
      if (onProgress != null) {
        onProgress(++count / total, p.basename(srcPath));
      }
    }
  }
  /// 2. 文件夹迁移：扁平化移动，成功后删除源文件夹
  Future<void> _moveDirectory(
      String src,
      String defaultDst,
      String rootStorage,
      Set<String> allowedExts,
      Set<String>? excludes,
      RegExp? idRegex,
      Function(double, String)? onProgress) async {

    final sourceDir = Directory(src);
    if (!await sourceDir.exists()) return;

    final sourceFolderName = p.basename(src);
    String targetBaseDir;
    String? matchedId;

    // ID 匹配逻辑保持不变
    if (idRegex != null && idRegex.hasMatch(sourceFolderName)) {
      matchedId = idRegex.firstMatch(sourceFolderName)!.group(0);
    }

    if (matchedId != null) {
      targetBaseDir = p.join(rootStorage, matchedId);
    } else {
      targetBaseDir = p.join(rootStorage, "未解析", sourceFolderName);
    }

    await Directory(targetBaseDir).create(recursive: true);

    // 遍历并移动
    // 注意：这里我们只处理文件，不处理空文件夹。
    // 原文件夹的删除操作放在最后统一处理。
    await for (var entity in sourceDir.list(recursive: true, followLinks: false)) {
      if (entity is File && _isTargetFile(entity.path, allowedExts, excludes)) {
        // 扁平化路径：丢弃原目录结构，直接放进 targetBaseDir
        final newPath = p.join(targetBaseDir, p.basename(entity.path));

        // ✅ 执行移动
        await _safeMoveFile(entity, newPath);

        if (onProgress != null) onProgress(0.5, p.basename(entity.path));
      }
    }

    // ✅ 清理步骤：删除源文件夹
    try {
      // 这里的 recursive: true 会删除原本剩下的非目标文件和空文件夹
      // 如果你希望保留非目标文件，需要写更复杂的逻辑判断 list().isEmpty
      await sourceDir.delete(recursive: true);
      print("源文件夹已清理: $src");
    } catch (e) {
      print("清理源文件夹失败 (可能被占用或权限不足): $e");
    }
  }
  // ==========================================
  // 3. 文件迁移逻辑 (New Feature)
  // ==========================================

  /// 将旧文件夹中的所有内容迁移到新文件夹
  /// [oldPath]: 旧的存储路径
  /// [newPath]: 新的存储路径
  /// [deleteOld]: 迁移成功后是否删除旧文件夹
  Future<void> migrateDirectory(
      String oldPath,
      String newPath, {
        bool deleteOld = true,
        void Function(int count, String currentFile)? onProgress,
      }) async {

    // 0. 打印日志进行调试 (关键步骤)
    print("准备迁移: \n旧路径: $oldPath \n新路径: $newPath");

    final oldDir = Directory(oldPath);
    final newDir = Directory(newPath);

    // 1. 基础检查
    // 如果旧目录物理上根本不存在，那么其实不需要“迁移”，直接结束即可
    if (!await oldDir.exists()) {
      print("⚠️ 迁移取消: 旧文件夹物理不存在 (可能从未创建过或已被删除)");
      return;
    }

    // 路径相同检查
    if (p.normalize(oldPath) == p.normalize(newPath)) {
      print("⚠️ 迁移取消: 新旧路径相同");
      return;
    }

    // 确保新目录存在
    await newDir.create(recursive: true);

    int count = 0;

    // 2. 遍历并移动
    try {
      await for (var entity in oldDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: oldPath);
          final newFilePath = p.join(newPath, relativePath);

          // 创建父目录
          await Directory(p.dirname(newFilePath)).create(recursive: true);

          try {
            await entity.rename(newFilePath);
          } catch (e) {
            // 跨分区移动备选方案
            await entity.copy(newFilePath);
            await entity.delete();
          }

          count++;
          // 打印每个移动的文件，确保逻辑在跑
          print("已迁移: $relativePath");
          if (onProgress != null) onProgress(count, p.basename(entity.path));
        }
      }
    } catch (e) {
      // 捕获 list() 可能出现的权限错误
      throw GlobalException("读取旧目录失败，请检查权限: $e");
    }

    // 3. 清理旧目录
    if (deleteOld) {
      try {
        // 只有当旧目录里面空了才删除，避免误删未迁移的文件
        if (await oldDir.list().isEmpty) {
          await oldDir.delete(recursive: true);
          print("旧目录已清理");
        }
      } catch (e) {
        print("清理旧目录警告: $e");
      }
    }
  }
  /// 3. 压缩包处理：解压后删除源压缩包
  Future<void> _extractAndConsumeArchive(
      String src,
      String defaultDst,
      String rootStorage,
      Set<String> allowedExts,
      Set<String>? excludes,
      RegExp? idRegex,
      Function(double, String)? onProgress,
      {int currentDepth = 0, int maxDepth = 3, bool parentMatched = false}) async {

    if (currentDepth > maxDepth) return;
    const recursiveExts = {'.zip', '.rar', '.7z', '.tar'};
    final inputStream = InputFileStream(src);
    bool extractSuccess = false; // 标记是否解压流程正常走完

    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      int total = archive.files.length;
      int count = 0;

      for (var file in archive.files) {
        if (!file.isFile) continue;

        final decodedName = CharsetCover.fixEncoding(file.name); // 假设你有这个辅助函数或用 CharsetCover
        final ext = p.extension(decodedName).toLowerCase();
        final isNested = recursiveExts.contains(ext);
        final isTarget = _isTargetFile(decodedName, allowedExts, excludes);

        if (!isNested && !isTarget) {
          count++;
          continue;
        }
        String targetDir;
        String relativeFilePath = decodedName;
        bool currentMatched = false;
        String? matchedId;

        // -- 为了代码完整性，简写路径判断逻辑 --
        if (idRegex != null) {
          final parts = p.split(decodedName);
          for (var part in parts) {
            if (idRegex.hasMatch(part)) {
              matchedId = idRegex.firstMatch(part)!.group(0);
              break;
            }
          }
        }
        if (matchedId != null) {
          targetDir = p.join(rootStorage, matchedId);
          currentMatched = true;
          final parts = p.split(decodedName);
          int idIndex = parts.indexWhere((part) => part.contains(matchedId!));
          if (idIndex != -1 && idIndex < parts.length - 1) {
            relativeFilePath = p.joinAll(parts.sublist(idIndex + 1));
          } else {
            relativeFilePath = p.basename(decodedName);
          }
        } else if (parentMatched) {
          targetDir = defaultDst;
          currentMatched = true;
          relativeFilePath = decodedName;
        } else {
          targetDir = p.join(rootStorage, "未解析");
          relativeFilePath = decodedName;
        }
        // -- 路径判断逻辑结束 --

        final outputFilePath = p.join(targetDir, relativeFilePath);

        // 安全检查：防止解压到根目录以外
        if (p.normalize(outputFilePath).startsWith(p.normalize(rootStorage))) {
          final outFile = File(outputFilePath);
          await outFile.parent.create(recursive: true);
          final outStream = OutputFileStream(outputFilePath);
          try {
            file.writeContent(outStream);
          } catch(e) {
            print(e);
          } finally {
            await outStream.close();
          }

          // 递归处理嵌套压缩包
          if (isNested) {
            await _extractAndConsumeArchive(outputFilePath, targetDir, rootStorage, allowedExts, excludes, idRegex, onProgress,
                currentDepth: currentDepth + 1, maxDepth: maxDepth, parentMatched: currentMatched);
            // 嵌套的压缩包解压完后，通常不需要保留作为结果文件（除非它是漫画本身），这里根据需求选择是否删除
            if (!isTarget) {
              try { await outFile.delete(); } catch(e){}
            }
          }
        }
        if (onProgress != null && currentDepth == 0) onProgress(++count / total, decodedName);
      }
      extractSuccess = true;
    } catch (e) {
      if (currentDepth == 0) rethrow;
      print("解压警告: $e");
    } finally {
      await inputStream.close();
    }

    // ✅ 核心修改：如果是最外层的压缩包，且流程没崩溃，则删除源文件
    if (currentDepth == 0 && extractSuccess) {
      try {
        final srcFile = File(src);
        if (await srcFile.exists()) {
          await srcFile.delete();
          print("源压缩包已删除: $src");
        }
      } catch (e) {
        print("删除源压缩包失败: $e");
      }
    }
  }

  bool _isTargetFile(String filePath, Set<String> allowedExts, Set<String>? excludes) {
    final name = p.basename(filePath);
    if (excludes != null) {
      for (var pattern in excludes) {
        if (name.contains(pattern)) return false;
      }
    }
    if (allowedExts.isEmpty) return true;
    return allowedExts.contains(p.extension(name).toLowerCase());
  }

  // Future<void> _copyMultipleFiles(
  //     List<String> files,
  //     String dstDir,
  //     Set<String> allowedExts,
  //     Set<String>? excludes,
  //     Function(double, String)? onProgress) async {
  //
  //   // ✅ 【核心修改】确保目标目录存在
  //   // 如果 dstDir 不存在，这行代码会创建它；如果已存在，则什么都不做。
  //   await Directory(dstDir).create(recursive: true);
  //
  //   int total = files.length;
  //   int count = 0;
  //
  //   for (var srcPath in files) {
  //     if (_isTargetFile(srcPath, allowedExts, excludes)) {
  //       final file = File(srcPath);
  //
  //       // 拼接目标路径
  //       final String newPath = p.join(dstDir, p.basename(srcPath));
  //
  //       // 执行复制
  //       await file.copy(newPath);
  //
  //       if (onProgress != null) {
  //         onProgress(++count / total, p.basename(srcPath));
  //       }
  //     } else {
  //       // (可选建议) 如果该文件被跳过，也应该算作“已处理”，避免进度条卡住
  //       // count++;
  //     }
  //   }
  // }

  // // 文件夹导入：扁平化处理 (根据你之前的要求)
  // Future<void> _copyDirectory(
  //     String src, String defaultDst, String rootStorage, Set<String> allowedExts, Set<String>? excludes, RegExp? idRegex, Function(double, String)? onProgress) async {
  //
  //   final sourceDir = Directory(src);
  //   final sourceFolderName = p.basename(src);
  //   String targetBaseDir;
  //   String? matchedId;
  //
  //   if (idRegex != null && idRegex.hasMatch(sourceFolderName)) {
  //     matchedId = idRegex.firstMatch(sourceFolderName)!.group(0);
  //   }
  //
  //   if (matchedId != null) {
  //     targetBaseDir = p.join(rootStorage, matchedId);
  //   } else {
  //     targetBaseDir = p.join(rootStorage, "未解析", sourceFolderName);
  //   }
  //
  //   await Directory(targetBaseDir).create(recursive: true);
  //
  //   await for (var entity in sourceDir.list(recursive: true, followLinks: false)) {
  //     if (entity is File && _isTargetFile(entity.path, allowedExts, excludes)) {
  //       // 扁平化：直接用 basename，丢弃子目录结构
  //       await entity.copy(p.join(targetBaseDir, p.basename(entity.path)));
  //       if (onProgress != null) onProgress(0.5, p.basename(entity.path)); // 简化进度
  //     }
  //   }
  // }

  // // 压缩包导入：递归解压 + 智能路径
  // Future<void> _extractArchive(String src, String defaultDst, String rootStorage, Set<String> allowedExts, Set<String>? excludes, RegExp? idRegex, Function(double, String)? onProgress,
  //     {int currentDepth = 0, int maxDepth = 3, bool parentMatched = false}) async {
  //
  //   if (currentDepth > maxDepth) return;
  //   const recursiveExts = {'.zip', '.rar', '.7z', '.tar'};
  //   final inputStream = InputFileStream(src);
  //
  //   try {
  //     final archive = ZipDecoder().decodeStream(inputStream);
  //     int total = archive.files.length;
  //     int count = 0;
  //
  //     for (var file in archive.files) {
  //       if (!file.isFile) continue;
  //
  //       final decodedName = CharsetCover.fixEncoding(file.name);
  //       final ext = p.extension(decodedName).toLowerCase();
  //       final isNested = recursiveExts.contains(ext);
  //       final isTarget = _isTargetFile(decodedName, allowedExts, excludes);
  //
  //       if (!isNested && !isTarget) {
  //         count++;
  //         continue;
  //       }
  //
  //       String targetDir;
  //       String relativeFilePath = decodedName;
  //       bool currentMatched = false;
  //       String? matchedId;
  //
  //       if (idRegex != null) {
  //         final parts = p.split(decodedName);
  //         for (var part in parts) {
  //           if (idRegex.hasMatch(part)) {
  //             matchedId = idRegex.firstMatch(part)!.group(0);
  //             break;
  //           }
  //         }
  //       }
  //
  //       if (matchedId != null) {
  //         targetDir = p.join(rootStorage, matchedId);
  //         currentMatched = true;
  //         // 路径裁剪逻辑
  //         final parts = p.split(decodedName);
  //         int idIndex = parts.indexWhere((part) => part.contains(matchedId!));
  //         if (idIndex != -1 && idIndex < parts.length - 1) {
  //           relativeFilePath = p.joinAll(parts.sublist(idIndex + 1));
  //         } else {
  //           relativeFilePath = p.basename(decodedName);
  //         }
  //       } else if (parentMatched) {
  //         targetDir = defaultDst;
  //         currentMatched = true;
  //         relativeFilePath = decodedName;
  //       } else {
  //         targetDir = p.join(rootStorage, "未解析");
  //         relativeFilePath = decodedName;
  //       }
  //
  //       final outputFilePath = p.join(targetDir, relativeFilePath);
  //
  //       if (p.normalize(outputFilePath).startsWith(p.normalize(rootStorage))) {
  //         final outFile = File(outputFilePath);
  //         await outFile.parent.create(recursive: true);
  //         final outStream = OutputFileStream(outputFilePath);
  //         try {
  //           file.writeContent(outStream);
  //         } catch(e) { print(e); } finally { await outStream.close(); }
  //
  //         if (isNested) {
  //           await _extractArchive(outputFilePath, targetDir, rootStorage, allowedExts, excludes, idRegex, onProgress,
  //               currentDepth: currentDepth + 1, maxDepth: maxDepth, parentMatched: currentMatched);
  //           if (!isTarget) {
  //             try { await outFile.delete(); } catch(e){}
  //           }
  //         }
  //       }
  //       if (onProgress != null && currentDepth == 0) onProgress(++count / total, decodedName);
  //     }
  //   } catch (e) {
  //     if (currentDepth == 0) rethrow;
  //   } finally {
  //     await inputStream.close();
  //   }
  // }
  // 辅助函数：安全移动文件（核心逻辑）
  // 优先尝试 rename (剪切)，如果失败（通常因为跨分区），则执行 copy + delete
  Future<void> _safeMoveFile(File sourceFile, String targetPath) async {
    try {
      // 确保目标父目录存在
      await Directory(p.dirname(targetPath)).create(recursive: true);

      // 尝试直接重命名（最快，毫秒级）
      await sourceFile.rename(targetPath);
    } catch (e) {
      // 跨分区移动或权限问题，回退方案：复制 -> 删除
      await sourceFile.copy(targetPath);
      await sourceFile.delete();
    }
  }
}