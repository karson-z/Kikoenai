import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/features/local_media/model/local_media_exclusion.dart';
import 'package:kikoenai/features/local_media/provider/local_media_exclusion_store.dart';

/// 本地排除记录仓库。测试可以覆盖它，避免依赖应用启动时的存储初始化。
final localMediaExclusionRepositoryProvider =
    Provider<LocalMediaExclusionStore>((ref) {
      final box = AppStorage.localMediaExclusionBox;
      final listenable = box.listenable();
      void refresh() => ref.invalidateSelf();
      listenable.addListener(refresh);
      ref.onDispose(() => listenable.removeListener(refresh));
      return LocalMediaExclusionStore(box);
    });

/// 当前扫描根目录的排除记录。记录变化后自动重建。
final localMediaExclusionsProvider = Provider.autoDispose
    .family<List<LocalMediaExclusion>, String>((ref, rootPath) {
      return ref
          .watch(localMediaExclusionRepositoryProvider)
          .readForRoot(rootPath);
    });

/// 恢复一条排除记录。记录变化会通过仓库监听刷新列表。
Future<void> restoreLocalMediaExclusion(
  WidgetRef ref,
  LocalMediaExclusion entry,
) {
  return ref.read(localMediaExclusionRepositoryProvider).remove(entry);
}
