import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai/core/model/file_node.dart';
import '../../../../core/service/file/file_scanner_service.dart';
import '../../../../core/service/file/file_scanner_worker.dart';

part 'file_scanner_state.freezed.dart';


@freezed
abstract class FileScannerState with _$FileScannerState {
  const factory FileScannerState({
    @Default([]) List<FileNode> roots,
    @Default([]) List<String> savedPaths,
    String? currentPath,
    @Default(WorkerState.idle) WorkerState status,
    @Default(ScanMode.audio) ScanMode scanMode,
    String? errorMessage,
    @Default(0) int scannedCount,
  }) = _FileScannerState;
}