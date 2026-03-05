import 'package:flutter/foundation.dart';
import 'package:kikoenai/core/model/file_node.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_worker.dart';

@immutable
class FileScannerState {
  final List<FileNode> roots;
  final List<String> savedPaths; // 已保存的路径列表（书签）
  final String? currentPath;     // 当前正在扫描/展示的路径
  final WorkerState status;
  final ScanMode scanMode;
  final String? errorMessage;
  final int scannedCount;

  const FileScannerState({
    this.roots = const [],
    this.savedPaths = const [],
    this.currentPath,
    this.status = WorkerState.idle,
    this.scanMode = ScanMode.audio,
    this.errorMessage,
    this.scannedCount = 0,
  });

  FileScannerState copyWith({
    List<FileNode>? roots,
    List<String>? savedPaths,
    String? currentPath,
    WorkerState? status,
    ScanMode? scanMode,
    String? errorMessage,
    int? scannedCount,
  }) {
    return FileScannerState(
      roots: roots ?? this.roots,
      savedPaths: savedPaths ?? this.savedPaths,
      currentPath: currentPath ?? this.currentPath,
      status: status ?? this.status,
      scanMode: scanMode ?? this.scanMode,
      errorMessage: errorMessage ?? this.errorMessage,
      scannedCount: scannedCount ?? this.scannedCount,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileScannerState &&
        listEquals(other.roots, roots) &&
        other.status == status &&
        other.scanMode == scanMode &&
        other.errorMessage == errorMessage &&
        other.scannedCount == scannedCount &&
        other.savedPaths == savedPaths &&
        other.currentPath == currentPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(roots),
      status,
      scanMode,
      errorMessage,
      scannedCount,
      savedPaths,
      currentPath,
    );
  }
}