import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
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

  static const Set<String> _archiveExtensions = {'.zip', '.rar', '.7z', '.tar'};

  // ==========================================
  // 1. 基础工具方法
  // ==========================================

  /// 权限检查
  Future<bool> requestPermissions() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return true;
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      if ((await Permission.manageExternalStorage.request()).isGranted) return true;
      return (await Permission.storage.request()).isGranted;
    }
    return true;
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
      if (_archiveExtensions.contains(ext)) {
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

  // ==========================================
  // 2. 核心导入逻辑
  // ==========================================
  String generateTargetPath(
      String firstPath,
      String rootTargetDir,
      ImportFileType type, {
        String? idRegexPattern,
      }) {
    // 1. 优先处理单文件/多文件
    if (type == ImportFileType.singleFile || type == ImportFileType.multipleFiles) {

      // 【新增逻辑】检查当前根目录是否已经匹配了正则（即是否已经处于 ID 文件夹内）
      if (idRegexPattern != null && idRegexPattern.isNotEmpty) {
        try {
          // 获取当前目标文件夹的名字 (例如 /storage/.../RJ123456 -> RJ123456)
          final rootDirName = p.basename(rootTargetDir);
          final regExp = RegExp(idRegexPattern, caseSensitive: false);

          // 如果当前文件夹名字本身就包含 ID (例如是 RJ123456)
          if (regExp.hasMatch(rootDirName)) {
            // 直接返回根目录，不创建日期文件夹
            return rootTargetDir;
          }
        } catch (e) {
          print("⚠️ 正则匹配当前目录出错: $e");
        }
      }

      // 【原有逻辑】如果没匹配上，还是按照日期归档
      final now = DateTime.now();
      String dateFolderName = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      return p.join(rootTargetDir, dateFolderName);
    }

    // 2. 下面处理文件夹/压缩包 (保持原有逻辑不变)
    String folderName = p.basenameWithoutExtension(firstPath);

    if (idRegexPattern != null && idRegexPattern.isNotEmpty) {
      try {
        final regExp = RegExp(idRegexPattern, caseSensitive: false);
        final match = regExp.firstMatch(folderName);
        if (match != null) {
          return p.join(rootTargetDir, match.group(0)!);
        }
        throw GlobalException("未能正确匹配文件");
      } catch (e) {
        print("⚠️ 正则表达式错误: $e");
      }
    }
    // 3. 如果没传正则，使用原始文件名
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
    // 确保目标根目录存在
    // await Directory(destinationPath).create(recursive: true);
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
        await _copyDirectory(
            sourcePaths.first, destinationPath, rootStorageDir, allowedExtensions, excludedPatterns, idRegExp, onProgress);
        break;
      case ImportFileType.archive:
        await _extractArchive(
            sourcePaths.first, destinationPath, rootStorageDir, allowedExtensions, excludedPatterns, idRegExp, onProgress,
            parentMatched: initialParentMatched);
        break;
      case ImportFileType.singleFile:
      case ImportFileType.multipleFiles:
        await _copyMultipleFiles(sourcePaths, destinationPath, allowedExtensions, excludedPatterns, onProgress);
        break;
      default:
        break;
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

  Future<void> _copyMultipleFiles(
      List<String> files,
      String dstDir,
      Set<String> allowedExts,
      Set<String>? excludes,
      Function(double, String)? onProgress) async {

    // ✅ 【核心修改】确保目标目录存在
    // 如果 dstDir 不存在，这行代码会创建它；如果已存在，则什么都不做。
    await Directory(dstDir).create(recursive: true);

    int total = files.length;
    int count = 0;

    for (var srcPath in files) {
      if (_isTargetFile(srcPath, allowedExts, excludes)) {
        final file = File(srcPath);

        // 拼接目标路径
        final String newPath = p.join(dstDir, p.basename(srcPath));

        // 执行复制
        await file.copy(newPath);

        if (onProgress != null) {
          onProgress(++count / total, p.basename(srcPath));
        }
      } else {
        // (可选建议) 如果该文件被跳过，也应该算作“已处理”，避免进度条卡住
        // count++;
      }
    }
  }

  // 文件夹导入：扁平化处理 (根据你之前的要求)
  Future<void> _copyDirectory(
      String src, String defaultDst, String rootStorage, Set<String> allowedExts, Set<String>? excludes, RegExp? idRegex, Function(double, String)? onProgress) async {

    final sourceDir = Directory(src);
    final sourceFolderName = p.basename(src);
    String targetBaseDir;
    String? matchedId;

    if (idRegex != null && idRegex.hasMatch(sourceFolderName)) {
      matchedId = idRegex.firstMatch(sourceFolderName)!.group(0);
    }

    if (matchedId != null) {
      targetBaseDir = p.join(rootStorage, matchedId);
    } else {
      targetBaseDir = p.join(rootStorage, "未解析", sourceFolderName);
    }

    await Directory(targetBaseDir).create(recursive: true);

    await for (var entity in sourceDir.list(recursive: true, followLinks: false)) {
      if (entity is File && _isTargetFile(entity.path, allowedExts, excludes)) {
        // 扁平化：直接用 basename，丢弃子目录结构
        await entity.copy(p.join(targetBaseDir, p.basename(entity.path)));
        if (onProgress != null) onProgress(0.5, p.basename(entity.path)); // 简化进度
      }
    }
  }

  // 压缩包导入：递归解压 + 智能路径
  Future<void> _extractArchive(String src, String defaultDst, String rootStorage, Set<String> allowedExts, Set<String>? excludes, RegExp? idRegex, Function(double, String)? onProgress,
      {int currentDepth = 0, int maxDepth = 3, bool parentMatched = false}) async {

    if (currentDepth > maxDepth) return;
    const recursiveExts = {'.zip', '.rar', '.7z', '.tar'};
    final inputStream = InputFileStream(src);

    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      int total = archive.files.length;
      int count = 0;

      for (var file in archive.files) {
        if (!file.isFile) continue;

        final decodedName = CharsetCover.fixEncoding(file.name);
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
          // 路径裁剪逻辑
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

        final outputFilePath = p.join(targetDir, relativeFilePath);

        if (p.normalize(outputFilePath).startsWith(p.normalize(rootStorage))) {
          final outFile = File(outputFilePath);
          await outFile.parent.create(recursive: true);
          final outStream = OutputFileStream(outputFilePath);
          try {
            file.writeContent(outStream);
          } catch(e) { print(e); } finally { await outStream.close(); }

          if (isNested) {
            await _extractArchive(outputFilePath, targetDir, rootStorage, allowedExts, excludes, idRegex, onProgress,
                currentDepth: currentDepth + 1, maxDepth: maxDepth, parentMatched: currentMatched);
            if (!isTarget) {
              try { await outFile.delete(); } catch(e){}
            }
          }
        }
        if (onProgress != null && currentDepth == 0) onProgress(++count / total, decodedName);
      }
    } catch (e) {
      if (currentDepth == 0) rethrow;
    } finally {
      await inputStream.close();
    }
  }
}