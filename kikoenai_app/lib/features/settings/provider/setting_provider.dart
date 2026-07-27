import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/playlist_filter.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/service/site/site_api_provider.dart';

// 1. 本地存储：管理用户选中的“默认播放列表”对象
// 我们存储整个 Playlist 对象（JSON），以便显示名称
final defaultMarkTargetPlaylistProvider =
NotifierProvider<DefaultMarkTargetPlaylistNotifier, Playlist?>(DefaultMarkTargetPlaylistNotifier.new);

class DefaultMarkTargetPlaylistNotifier extends Notifier<Playlist?> {

  @override
  Playlist? build() {
    // 1. 初始化时，直接从本地 Hive 缓存读取
    final playList = CacheService.instance.getQuickMarkTargetPlaylist();
    if (playList == null) {
      fetchAndCacheDefault();
    }
    return CacheService.instance.getQuickMarkTargetPlaylist();
  }

  /// 更新选中的播放列表（用户手动选择）
  Future<void> setPlaylist(Playlist playlist) async {
    state = playlist;
    // 同步保存到本地缓存
    await CacheService.instance.saveQuickMarkTargetPlaylist(playlist);
  }
  Future<void> fetchAndCacheDefault() async {
    try {
      if(CacheService.instance.getAuthSession() == null || !CacheService.instance.getAuthSession()!.isSuccess){
        return;
      }
      final api = ref.read(siteApiProvider);

      // 调用我们在 API 中新加的方法
      final playlist = await api.fetchDefaultMarkTargetPlaylist();

      // 更新状态并缓存
      state = playlist;
      await CacheService.instance.saveQuickMarkTargetPlaylist(playlist);
    } catch (e) {
      // 可以在这里处理错误，例如记录日志
      print('获取默认标记列表失败: $e');
      rethrow;
    }
  }

  /// 清除设置
  Future<void> clear() async {
    state = null;
    await CacheService.instance.clearQuickMarkTargetPlaylist();
  }
}

final allMyPlaylistsProvider = FutureProvider.autoDispose<List<Playlist>>((ref) async {
  if(CacheService.instance.getAuthSession() == null || !CacheService.instance.getAuthSession()!.isSuccess){
    return List.empty();
  }
  final api = ref.watch(siteApiProvider);

  final response = await api.fetchPlaylists(
    page: 1,
    pageSize: 50, // 取前50个，通常够用了
    filterBy: PlaylistFilter.owned.name,
  );

  return response.items;
});