import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai/features/local_media/provider/file_scanner_notifier.dart';

/// 面包屑所属界面：本地媒体库 / 作品详情 / 播放器文件管理弹窗。
enum BreadCrumbBarType { local, detail, player }

/// 基于 [FileNodeLibraryIndex] 的面包屑状态管理。
///
/// - [BreadCrumbBarType.local]：自动同步 [fileScannerProvider]，导航委托给
///   [FileScannerNotifier]（它内部已持有 [FileNodeLibraryIndex]）。
/// - [BreadCrumbBarType.detail] / [BreadCrumbBarType.player]：通过 [bindIndex]
///   绑定一个 [FileNodeLibraryIndex]，导航直接操作该索引。
///
/// state 恒为当前从根目录（不含）到所在文件夹的 [FileNode] 链；处于根目录时为空。
class BreadcrumbNotifier extends Notifier<List<FileNode>> {
  BreadcrumbNotifier(this.type);

  final BreadCrumbBarType type;

  /// detail / player 类型持有的索引（local 类型不使用，直接读 scanner）。
  FileNodeLibraryIndex? _index;

  @override
  List<FileNode> build() {
    if (type == BreadCrumbBarType.local) {
      // scanner 状态变化时，从其内部索引同步面包屑链。
      ref.listen(fileScannerProvider, (_, __) {
        state = _localPath();
      });
    }
    return _localPath();
  }

  List<FileNode> _localPath() {
    if (type != BreadCrumbBarType.local) return [];
    return ref.read(fileScannerProvider.notifier).libraryIndex?.breadcrumbPath ??
        const [];
  }

  /// 绑定索引（detail / player 类型）。绑定后立即刷新面包屑链。
  void bindIndex(FileNodeLibraryIndex index) {
    _index = index;
    _refresh();
  }

  /// 进入下一级目录。
  void enterFolder(FileNode node) {
    final folderPath = node.path ?? node.mediaStreamUrl ?? '';
    if (folderPath.isEmpty) return;
    final folder = NodeFolder(folderPath);

    if (type == BreadCrumbBarType.local) {
      ref.read(fileScannerProvider.notifier).stepIn(folder);
      return;
    }
    _index?.stepIn(folder);
    _refresh();
  }

  /// 返回上一级目录。
  void navigateBack() {
    if (type == BreadCrumbBarType.local) {
      ref.read(fileScannerProvider.notifier).stepOut();
      return;
    }
    _index?.stepOut();
    _refresh();
  }

  /// 跳转到指定层级（-1 代表根目录）。
  void jumpTo(int index) {
    if (type == BreadCrumbBarType.local) {
      ref.read(fileScannerProvider.notifier).jumpToBreadcrumbIndex(index);
      return;
    }
    _index?.jumpToBreadcrumbIndex(index);
    _refresh();
  }

  /// 回到根目录。
  void goHome() {
    if (type == BreadCrumbBarType.local) {
      ref.read(fileScannerProvider.notifier).goHome();
      return;
    }
    _index?.goHome();
    _refresh();
  }

  /// 始终用新列表实例替换 state，确保即使内容相同也能触发 UI 重建。
  void _refresh() {
    state = [...?(_index?.breadcrumbPath)];
  }
}

/// 暴露给 UI 的 Provider。
final breadcrumbProvider = NotifierProvider.family.autoDispose<
    BreadcrumbNotifier, List<FileNode>, BreadCrumbBarType>(
  BreadcrumbNotifier.new,
);
