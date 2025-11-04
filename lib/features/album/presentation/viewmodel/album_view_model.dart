import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:name_app/core/domain/errors.dart';
import 'package:name_app/features/album/data/model/album_res.dart';
import 'package:name_app/features/album/data/service/album_repository.dart';

/// 业务逻辑层，处理专辑相关业务
class AlbumViewModel extends ChangeNotifier {
  final AlbumRepository albumRepository;
  AlbumViewModel({AlbumRepository? repository})
      : albumRepository = repository ?? GetIt.I<AlbumRepository>();

  List<AlbumResponse> _albums = [];
  bool _loading = false;
  Failure? _error;
  bool get loading => _loading;
  Failure? get error => _error;
  List<AlbumResponse> get albums => _albums;

  /// 加载专辑列表
  Future<void> featchAlbums() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await albumRepository.getAlbumPageList();

      _loading = false;
      if (result.isSuccess) {
        _albums = result.data?.records ?? [];
      } else {
        _error = result.error;
      }
    } catch (e) {
      _loading = false;
      _error = mapException(e);
    }

    notifyListeners();
  }
}
