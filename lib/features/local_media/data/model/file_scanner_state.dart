import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';
import 'package:kikoenai/core/model/file_node.dart';
import '../../../../core/service/file/scan_mode.dart';

part 'file_scanner_state.freezed.dart';
part 'file_scanner_state.g.dart';

@freezed
@HiveType(typeId: TypeIds.scanTarget, adapterName: 'ScanTargetAdapter')
abstract class ScanTarget with _$ScanTarget {
  const factory ScanTarget({
    @HiveField(0) required String path,
    @HiveField(1) required int addedAt,
    @HiveField(2) int? lastScannedAt,
    @HiveField(3) required ScanMode scanMode,
  }) = _ScanTarget;

  factory ScanTarget.fromJson(Map<String, dynamic> json) =>
      _$ScanTargetFromJson(json);
}

@freezed
abstract class FileBrowserState with _$FileBrowserState {
  const FileBrowserState._();

  const factory FileBrowserState({
    /// 当前扫描目标的根路径
    required String rootPath,

    @Default(ScanMode.audio) ScanMode scanMode,

    /// 当前所处文件夹的路径
    String? currentFolderPath,

    /// 当前目录下要渲染的子项列表
    @Default([]) List<FileNode> children,

    /// 是否正在进行底层文件扫描
    @Default(false) bool isScanning,

    /// 是否处于根目录
    @Default(true) bool isHome,
  }) = _FileBrowserState;

  List<String> get breadcrumbPaths {
    final normalizedRoot = rootPath.replaceAll('\\', '/');
    final normalizedCurrent = (currentFolderPath ?? rootPath).replaceAll(
      '\\',
      '/',
    );

    if (normalizedCurrent.isEmpty ||
        normalizedRoot.isEmpty ||
        !normalizedCurrent.startsWith(normalizedRoot)) {
      return const [];
    }
    final relativePath = normalizedCurrent.substring(normalizedRoot.length);
    return relativePath.split('/').where((e) => e.isNotEmpty).toList();
  }
}
