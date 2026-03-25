import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';
import 'package:kikoenai/features/playlist/presentation/provider/playlist_filter_provider.dart';
import '../../../../core/enums/playlist_filter.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import '../../data/model/playlist_response.dart';
import '../../data/model/playlist_work_response.dart';
import '../../data/service/playlist_repository.dart';


typedef PlaylistQueryParams = ({int page, String filterBy});

final fetchPlaylistsProvider = FutureProvider.family<PlaylistListResponse, PlaylistQueryParams>(
      (ref, params) async {
    final repository = ref.watch(playlistRepositoryProvider);


    // 3. 将 String 类型的 filterBy 转为枚举
    final filterEnum = PlaylistFilter.values.firstWhere(
          (e) => e.name == params.filterBy,
      orElse: () => PlaylistFilter.all,
    );

    // 4. 发起请求
    return repository.fetchPlaylists(
      page: params.page,
      filterBy: filterEnum,
    );
  },
);



final playlistWorksProvider = AsyncNotifierProvider.autoDispose.family<PlaylistWorksNotifier, PlaylistWorksResponse, String>(
  PlaylistWorksNotifier.new,
);

class PlaylistWorksNotifier extends AsyncNotifier<PlaylistWorksResponse> {
  PlaylistWorksNotifier(this.playlistId);
  final String playlistId;
  int _page = 1;
  final int _pageSize = 20;

  @override
  Future<PlaylistWorksResponse> build() async {
    _page = 1;
    return _fetchData(page: 1, playlistId: playlistId);
  }

  Future<PlaylistWorksResponse> _fetchData({
    required int page,
    required String playlistId,
  }) async {
    final repository = ref.read(playlistRepositoryProvider);
    final uiState = ref.read(playlistUiProvider);
    final request = uiState.request;
    final shouldPost = request.tags.isNotEmpty ||
        request.textKeyword.isNotEmpty ||
        request.subtitlesOnly == true ||
        request.orderBy.value != 'create_date'; // 检查是否非默认排序

    if (shouldPost) {
      final pagedRequest = request.copyWith(
        id: playlistId,
        page: page,
        pageSize: _pageSize,
      );
      return repository.fetchPlaylistWorksByKeyword(pagedRequest);
    } else {
      return repository.fetchPlaylistWorks(
        playlistId: playlistId,
        page: page,
        pageSize: _pageSize,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasValue) return;

    final currentData = state.value!;
    if (currentData.works.length >= currentData.pagination.totalCount) return;

    final nextPage = _page + 1;
    try {
      final newResponse = await _fetchData(page: nextPage, playlistId: playlistId);

      state = AsyncValue.data(
        currentData.copyWith(
          works: [...currentData.works, ...newResponse.works],
          pagination: newResponse.pagination,
        ),
      );

      _page = nextPage;
    } catch (e) {
      print("加载更多失败: $e");
    }
  }
}

final playlistWorksMutationProvider = AsyncNotifierProvider.autoDispose<PlaylistWorksMutationController, void>(
  PlaylistWorksMutationController.new,
);

class PlaylistWorksMutationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> addWorks({required String playlistId, required List<int> workIds}) async {
    return _mutate(
      playlistId: playlistId,
      requestAction: () => ref.read(playlistRepositoryProvider).addWorksToPlaylist(
        playlistId: playlistId,
        workIds: workIds,
      ),
    );
  }

  Future<bool> removeWorks({required String playlistId, required List<int> workIds}) async {
    return _mutate(
      playlistId: playlistId,
      requestAction: () => ref.read(playlistRepositoryProvider).removeWorksFromPlaylist(
        playlistId: playlistId,
        workIds: workIds,
      ),
    );
  }

  Future<bool> _mutate({
    required String playlistId,
    required Future<Map<String, dynamic>> Function() requestAction,
  }) async {
    // 鉴权前置拦截
    final authState = ref.read(authNotifierProvider).value;
    if (authState == null || !authState.isLoggedIn) {
      // 抛出明确的未登录异常，交由 UI 层处理交互
      KikoenaiToast.error("请先登录");
      return false;
    }

    state = const AsyncLoading();

    try {
      final res = await requestAction();

      if (res['rowCount'] != null && res['rowCount'] > 0) {
        state = const AsyncData(null);
        ref.invalidate(playlistWorksProvider(playlistId));
        return true;
      }
      state = const AsyncData(null);
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}