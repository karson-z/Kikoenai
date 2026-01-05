import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/common/global_exception.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';

import '../../../../core/enums/playlist_filter.dart';
import '../model/playlist.dart';
import '../model/playlist_request.dart';
import '../model/playlist_response.dart';
import '../model/playlist_work_response.dart';

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
    try {
      final response = await api.get(
        '/playlist/get-playlists',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'filterBy': filterBy.name,
        },
      );
      return PlaylistListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw GlobalException("${e.message}");
    }
  }

  @override
  Future<PlaylistWorksResponse> fetchPlaylistWorks({
    required String playlistId,
    required int page,
    int pageSize = 12,
  }) async {
    try {
      final response = await api.get(
        '/playlist/get-playlist-works',
        queryParameters: {
          'id': playlistId,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PlaylistWorksResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw GlobalException("${e.message}");
    }
  }

  @override
  Future<Playlist> fetchDefaultMarkTargetPlaylist() async {
    try {
      final response = await api.get('/playlist/get-default-mark-target-playlist');
      return Playlist.fromJson(response.data);
    } on DioException catch (e) {
      throw GlobalException("${e.message}");
    }
  }

  @override
  Future<PlaylistWorksResponse> fetchPlaylistWorksByKeyword(PlaylistWorksRequest request) async {
    try {
      final response = await api.post(
        '/playlist/get-playlist-works-by-keyword',
        data: request.toJson(),
      );

      return PlaylistWorksResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw GlobalException("${e.message}");
    }
  }

}

final playlistRepositoryProvider = Provider<PlaylistRepositoryImpl>((ref) {
  final api = ref.read(apiClientProvider);
  return PlaylistRepositoryImpl(api);
});