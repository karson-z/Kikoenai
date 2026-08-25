import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/playlist_filter.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/service/site/site_api_provider.dart';

// 1. 本地存储：管理用户选中的“默认播放列表”对象
// 我们存储整个 Playlist 对象（JSON），以便显示名称
final defaultMarkTargetPlaylistProvider =
    NotifierProvider<DefaultMarkTargetPlaylistNotifier, Playlist?>(
      DefaultMarkTargetPlaylistNotifier.new,
    );

class DefaultMarkTargetPlaylistNotifier extends Notifier<Playlist?> {
  @override
  Playlist? build() {
    final siteId = ref.watch(activeSiteIdProvider);
    // 1. 初始化时，直接从本地 Hive 缓存读取
    final playList = CacheService.instance.getQuickMarkTargetPlaylist(
      siteId: siteId,
    );
    if (playList == null) {
      fetchAndCacheDefault();
    }
    return playList;
  }

  /// 更新选中的播放列表（用户手动选择）
  Future<void> setPlaylist(Playlist playlist) async {
    final siteId = ref.read(activeSiteIdProvider);
    state = playlist;
    // 同步保存到本地缓存
    await CacheService.instance.saveQuickMarkTargetPlaylist(
      playlist,
      siteId: siteId,
    );
  }

  Future<void> fetchAndCacheDefault() async {
    try {
      final siteId = ref.read(activeSiteIdProvider);
      final auth = CacheService.instance.getAuthSession(siteId: siteId);
      if (auth == null || !auth.isSuccess) {
        return;
      }
      final api = ref.read(activeSiteApiProvider);
      final Playlist playlist;
      if (api.supports(SiteFeature.defaultMarkTargetPlaylist)) {
        playlist = await api.fetchDefaultMarkTargetPlaylist();
      } else {
        if (!api.supports(SiteFeature.playlists)) return;
        final response = await api.fetchPlaylists(page: 1, pageSize: 1);
        if (response.items.isEmpty) return;
        playlist = response.items.first;
      }

      // 更新状态并缓存
      state = playlist;
      await CacheService.instance.saveQuickMarkTargetPlaylist(
        playlist,
        siteId: siteId,
      );
    } catch (e) {
      // 可以在这里处理错误，例如记录日志
      print('获取默认标记列表失败: $e');
      rethrow;
    }
  }

  /// 清除设置
  Future<void> clear() async {
    final siteId = ref.read(activeSiteIdProvider);
    state = null;
    await CacheService.instance.clearQuickMarkTargetPlaylist(siteId: siteId);
  }
}

final allMyPlaylistsProvider = FutureProvider.autoDispose<List<Playlist>>((
  ref,
) async {
  final siteId = ref.watch(activeSiteIdProvider);
  final auth = CacheService.instance.getAuthSession(siteId: siteId);
  if (auth == null || !auth.isSuccess) {
    return List.empty();
  }
  final api = ref.watch(activeSiteApiProvider);
  if (!api.supports(SiteFeature.playlists)) return List.empty();

  final response = await api.fetchPlaylists(
    page: 1,
    pageSize: 50, // 取前50个，通常够用了
    filterBy: PlaylistFilter.owned.name,
  );

  return response.items;
});
