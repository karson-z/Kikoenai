import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/local_media/presentation/provider/file_scanner_notifier.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

import '../../../../core/service/file/file_scanner_service.dart';
import '../../data/repository/scanner_path_repository.dart';

class ScanTargets extends Notifier<List<ScanTarget>> {
  final ScannerPathRepository _repository = ScannerPathRepository.instance;

  @override
  List<ScanTarget> build() {
    return _repository.getAllTargets();
  }

  List<ScanTarget> getTargetsByMode(ScanMode mode) {
    return state.where((target) => target.scanMode == mode).toList();
  }

  /// 添加扫描目标
  Future<ScanTarget?> addTarget({
    required String path,
    required ScanMode mode,
  }) async {
    if (_repository.isPathExists(path, mode)) {
      return null;
    }
    final target = ScanTarget(
      path: path,
      addedAt: DateTime.now().millisecondsSinceEpoch,
      scanMode: mode,
    );
    await _repository.saveTarget(target);
    state = _repository.getAllTargets();
    return target;
  }

  ScanTarget? getActiveTarget() {
    return _repository.getActiveTarget();
  }

  Future<void> selectTarget({
    required String path,
    required ScanMode mode,
  }) async {
    final scanTarget = _repository.getTarget(path, mode);
    if (scanTarget == null) return;

    await _repository.saveActiveTarget(scanTarget);
    state = _repository.getAllTargets();
  }

  /// 删除扫描目标
  Future<void> removeTarget({
    required String path,
    required ScanMode mode,
  }) async {
    final fileScannerNotifier = ref.read(fileScannerProvider.notifier);
    final activeState = fileScannerNotifier.state;

    // 1. 判断被删除的路径是否是当前全局激活查看的路径
    final isRemovingCurrentActive =
        activeState.rootPath == path && activeState.scanMode == mode;

    // 2. 使用你的 _repository 组件执行物理删除与 FileNode 缓存联动清理
    await _repository.deleteTarget(path, mode);

    // 3. 联动逻辑：如果是删除当前的正在查看的路径，寻找同个模式下的第一个路径补位
    if (isRemovingCurrentActive) {
      // 通过你的 _repository 捞出该模式下删除后【剩余】的所有有效路径
      final remainingTargetsOfMode = _repository.getTargetsByMode(mode);

      if (remainingTargetsOfMode.isNotEmpty) {
        // 策略 A：同个模式下还有其他路径，自动找第一个路径进行覆盖展示
        final firstTarget = remainingTargetsOfMode.first;

        // 更新全局唯一的活动指针对象
        await _repository.saveActiveTarget(firstTarget);
        // 驱动控制中心无缝切流并重载扫描任务
        fileScannerNotifier.changeActiveTarget(firstTarget);
      } else {
        // 策略 B：删除后该模式下彻底空了，直接进行置空兜底
        fileScannerNotifier.handleCurrentPathRemoved();
      }
    }

    // 4. 刷新当前 Notifier 的全量状态列表，促使 UI 视图收缩并重绘
    state = _repository.getAllTargets();
  }

  /// 更新某个路径的最后扫描时间
  Future<void> updateScanTime({
    required String path,
    required ScanMode mode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _repository.updateLastScannedAt(path, mode, now);
    state = _repository.getAllTargets();
  }

  Future<void> refreshTargets() async {
    state = _repository.getAllTargets();
  }
}

final scanTargetsProvider = NotifierProvider<ScanTargets, List<ScanTarget>>(() {
  return ScanTargets();
});
