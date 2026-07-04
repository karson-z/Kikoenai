import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/global_exception.dart';
import 'package:kikoenai/core/service/file/file_scanner_storage.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import 'package:kikoenai/features/album/presentation/widget/file_box.dart';


/// 作品详情页文件区段基类。
///
/// 本地与网络两种来源分别由 [LocalAlbumFileSection] / [RemoteAlbumFileSection]
/// 实现，由承接层根据 `isLocal` 选择具体子类，避免在视图层用 `if` 切换。
/// 每个 [build] 均返回一个 Sliver，直接嵌入详情页的 [CustomScrollView]。
abstract class AlbumFileSection extends ConsumerWidget {
  const AlbumFileSection({super.key});
}

/// 本地作品文件区段：直接从 [FileScannerStorage] 读取已扫描的本地文件树。
class LocalAlbumFileSection extends AlbumFileSection {
  const LocalAlbumFileSection({super.key, required this.work});

  final Work work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localWorkTree = FileScannerStorage().getWorkFileTreeLocally(work.id);

    if (localWorkTree == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('本地未找到该作品的文件', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (localWorkTree.children == null || localWorkTree.children!.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('该文件夹内部为空', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return FileNodeBrowser(
      work: work,
      rootNodes: localWorkTree.children!,
      isLocal: true,
    );
  }
}

/// 网络作品文件区段：监听 [trackFileNodeProvider] 并处理加载 / 错误 / 数据三态。
class RemoteAlbumFileSection extends AlbumFileSection {
  const RemoteAlbumFileSection({super.key, required this.work});

  final Work work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(trackFileNodeProvider(work.id));

    return asyncData.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: LottieLoadingIndicator(message: 'loading...')),
      ),
      error: (err, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: err is GlobalException
              ? Text('GlobalException: ${err.message}\ncode=${err.code}')
              : Text('Error: $err'),
        ),
      ),
      data: (nodes) => FileNodeBrowser(
        work: work,
        rootNodes: nodes,
        isLocal: false,
      ),
    );
  }
}
