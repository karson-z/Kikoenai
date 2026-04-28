import 'package:kikoenai/core/model/file_node.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_worker.dart';

enum ScanSyncStatus {
  empty,
  fresh,
  stale,
  refreshing,
  error,
}

class FileScannerState {
  static const Object _unset = Object();

  final List<FileNode> roots;
  final List<String> savedPaths;
  final String? currentPath;
  final WorkerState status;
  final ScanMode scanMode;
  final String? errorMessage;
  final int scannedCount;
  final ScanSyncStatus syncStatus;
  final DateTime? lastSuccessfulScanAt;
  final bool hasCachedData;
  final bool isDirty;

  const FileScannerState({
    this.roots = const [],
    this.savedPaths = const [],
    this.currentPath,
    this.status = WorkerState.idle,
    this.scanMode = ScanMode.audio,
    this.errorMessage,
    this.scannedCount = 0,
    this.syncStatus = ScanSyncStatus.empty,
    this.lastSuccessfulScanAt,
    this.hasCachedData = false,
    this.isDirty = false,
  });

  bool get isRefreshing => syncStatus == ScanSyncStatus.refreshing;

  FileScannerState copyWith({
    List<FileNode>? roots,
    List<String>? savedPaths,
    Object? currentPath = _unset,
    WorkerState? status,
    ScanMode? scanMode,
    Object? errorMessage = _unset,
    int? scannedCount,
    ScanSyncStatus? syncStatus,
    Object? lastSuccessfulScanAt = _unset,
    bool? hasCachedData,
    bool? isDirty,
  }) {
    return FileScannerState(
      roots: roots ?? this.roots,
      savedPaths: savedPaths ?? this.savedPaths,
      currentPath: identical(currentPath, _unset)
          ? this.currentPath
          : currentPath as String?,
      status: status ?? this.status,
      scanMode: scanMode ?? this.scanMode,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      scannedCount: scannedCount ?? this.scannedCount,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSuccessfulScanAt: identical(lastSuccessfulScanAt, _unset)
          ? this.lastSuccessfulScanAt
          : lastSuccessfulScanAt as DateTime?,
      hasCachedData: hasCachedData ?? this.hasCachedData,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
