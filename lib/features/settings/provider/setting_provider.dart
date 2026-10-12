import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/playlist_filter.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/service/site/site_api_provider.dart';
import '../../auth/provider/auth_provider.dart';

// 1. 本地存储：管理用户选中的“默认播放列表”对象
// 我们存储整个 Playlist 对象（JSON），以便显示名称
final defaultMarkTargetPlaylistProvider =
    AsyncNotifierProvider<DefaultMarkTargetPlaylistNotifier, Playlist?>(
  DefaultMarkTargetPlaylistNotifier.new,
);

class DefaultMarkTargetPlaylistNotifier extends AsyncNotifier<Playlist?> {
  @override
  Future<Playlist?> build() async {
    final siteId = ref.watch(activeSiteIdProvider);
    final auth = ref.watch(authNotifierProvider).value;
    final cachedPlaylist = CacheService.instance.getQuickMarkTargetPlaylist(
      siteId: siteId,
    );
    if (cachedPlaylist != null) return cachedPlaylist;
    if (auth?.isLoggedIn != true) return null;
    return _fetchAndCacheDefault(siteId);
  }

  /// 更新选中的播放列表（用户手动选择）
  Future<void> setPlaylist(Playlist playlist) async {
    final siteId = ref.read(activeSiteIdProvider);
    state = AsyncData(playlist);
    // 同步保存到本地缓存
    await CacheService.instance.saveQuickMarkTargetPlaylist(
      playlist,
      siteId: siteId,
    );
  }

  Future<Playlist?> _fetchAndCacheDefault(String siteId) async {
    try {
      final auth = CacheService.instance.getAuthSession(siteId: siteId);
      if (auth == null || !auth.isSuccess) {
        return null;
      }
      final api = ref.read(siteApiByIdProvider(siteId));
      final Playlist playlist;
      if (api.supports(SiteFeature.defaultMarkTargetPlaylist)) {
        playlist = await api.fetchDefaultMarkTargetPlaylist();
      } else {
        if (!api.supports(SiteFeature.playlists)) return null;
        final response = await api.fetchPlaylists(page: 1, pageSize: 1);
        if (response.items.isEmpty) return null;
        playlist = response.items.first;
      }

      await CacheService.instance.saveQuickMarkTargetPlaylist(
        playlist,
        siteId: siteId,
      );
      return playlist;
    } catch (e) {
      print('获取默认标记列表失败: $e');
      rethrow;
    }
  }

  /// 清除设置
  Future<void> clear() async {
    final siteId = ref.read(activeSiteIdProvider);
    state = const AsyncData(null);
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
