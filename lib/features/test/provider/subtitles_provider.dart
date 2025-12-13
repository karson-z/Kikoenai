import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import '../../../core/service/path_setting_service.dart'; // 你的 StorageKeys

// ==========================================
// 2. Riverpod Providers (已更新)
// ==========================================

/// 【核心修改】存储字幕的根目录
/// 现在改为从 PathSettingsService 获取配置的路径
final subtitleRootProvider = FutureProvider<String>((ref) async {
  final pathService = PathSettingsService();
  // 获取用户设置的 'Subtitle' 路径
  final path = await pathService.getPath(StorageKeys.pathSubtitle);

  // 双重保险：确保拿到的这个路径文件夹确实存在
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return path;
});

/// 当前浏览的路径状态 (默认是 null，代表根目录)
final currentPathProvider = StateProvider<String?>((ref) => null);

/// 获取当前路径下的文件列表
final directoryContentsProvider = FutureProvider.autoDispose<List<FileSystemEntity>>((ref) async {
  // 1. 等待根目录获取完成
  final rootPath = await ref.watch(subtitleRootProvider.future);

  // 2. 确定当前要显示的目录 (如果没有选中子目录，就显示根目录)
  final currentPath = ref.watch(currentPathProvider) ?? rootPath;

  final dir = Directory(currentPath);
  if (!await dir.exists()) return [];

  // 3. 列出文件并排序
  final List<FileSystemEntity> entities = await dir.list().toList();

  // 排序规则：文件夹在前，文件在后；同类按名称排序
  entities.sort((a, b) {
    bool aIsDir = FileSystemEntity.isDirectorySync(a.path);
    bool bIsDir = FileSystemEntity.isDirectorySync(b.path);
    if (aIsDir && !bIsDir) return -1;
    if (!aIsDir && bIsDir) return 1;
    return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
  });

  return entities;
});