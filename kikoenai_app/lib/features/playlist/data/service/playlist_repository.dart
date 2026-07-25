import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/playlist_filter.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

abstract class PlaylistRepository {
  Future<PlaylistListResponse> fetchPlaylists({
    required int page,
    int pageSize = 20,
    PlaylistFilter filterBy = PlaylistFilter.all,
  });

  Future<PlaylistWorksResponse> fetchPlaylistWorks({
    required String playlistId,
    required int page,
    int pageSize = 12,
  });

  Future<Map<String,dynamic>> addWorksToPlaylist({
    required String playlistId,
    required List<int> workIds,
  });

  Future<Map<String,dynamic>> removeWorksFromPlaylist({
    required String playlistId,
    required List<int> workIds,
  });


  Future<Playlist> fetchDefaultMarkTargetPlaylist();

  Future<PlaylistWorksResponse> fetchPlaylistWorksByKeyword(PlaylistWorksRequest request);
}

class PlaylistRepositoryImpl implements PlaylistRepository {
  final ApiClient api;

  PlaylistRepositoryImpl(this.api);

  @override
  Future<PlaylistListResponse> fetchPlaylists({
    required int page,
    int pageSize = 20,
    PlaylistFilter filterBy = PlaylistFilter.all,
  }) async {
    final response = await api.get<Map<String, dynamic>>(
      '/playlist/get-playlists',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'filterBy': filterBy.name,
      },
    );
    return PlaylistListResponse.fromJson(response);
  }

  @override
  Future<PlaylistWorksResponse> fetchPlaylistWorks({
    required String playlistId,
    required int page,
    int pageSize = 12,
  }) async {
    final response = await api.get<Map<String, dynamic>>(
      '/playlist/get-playlist-works',
      queryParameters: {
        'id': playlistId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PlaylistWorksResponse.fromJson(response);
  }

  @override
  Future<Playlist> fetchDefaultMarkTargetPlaylist() async {
    final response =
        await api.get<Map<String, dynamic>>('/playlist/get-default-mark-target-playlist');
    return Playlist.fromJson(response);
  }

  @override
  Future<PlaylistWorksResponse> fetchPlaylistWorksByKeyword(PlaylistWorksRequest request) async {
    final response = await api.post<Map<String, dynamic>>(
      '/playlist/get-playlist-works-by-keyword',
      data: request.toJson(),
    );

    return PlaylistWorksResponse.fromJson(response);
  }

  @override
  Future<Map<String, dynamic>> addWorksToPlaylist({required String playlistId, required List<int> workIds}) async {
    return api.post<Map<String, dynamic>>('/playlist/add-works-to-playlist',
      data: {
        'playlistId': playlistId,
        'works': workIds,
      }
    );
  }

  @override
  Future<Map<String, dynamic>> removeWorksFromPlaylist({required String playlistId, required List<int> workIds}) async {
    return api.post<Map<String, dynamic>>('/playlist/remove-works-from-playlist',
        data: {
          'playlistId': playlistId,
          'works': workIds,
        }
    );
  }
}

final playlistRepositoryProvider = Provider<PlaylistRepositoryImpl>((ref) {
  final api = ref.read(apiClientProvider);
  return PlaylistRepositoryImpl(api);
});
