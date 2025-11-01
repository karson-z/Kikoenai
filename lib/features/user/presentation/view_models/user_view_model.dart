import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/user_model.dart';
import '../../domain/user_usecases.dart';
import 'package:name_app/core/domain/result.dart';
import 'package:name_app/core/domain/errors.dart';

class UserViewModel extends ChangeNotifier {
  final GetUsersUseCase _getUsersUseCase;

  UserViewModel({GetUsersUseCase? useCase})
      : _getUsersUseCase = useCase ?? GetIt.I<GetUsersUseCase>();

  bool _loading = false;
  Failure? _error;
  List<UserModel> _users = [];

  // 分页状态
  int _page = 0; // 基于 0 的页索引
  final int _pageSize = 10;
  bool _hasMore = true;

  bool get loading => _loading;
  Failure? get error => _error;
  List<UserModel> get users => _users;
  bool get hasMore => _hasMore;

  Future<void> fetchFirstPage() async {
    _page = 0;
    _hasMore = true;
    _users = [];
    await _fetchPage(reset: true);
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    await _fetchPage();
  }

  Future<void> refresh() async {
    await fetchFirstPage();
  }

  Future<void> _fetchPage({bool reset = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final start = _page * _pageSize;
      final Result<List<UserModel>> res = await _getUsersUseCase.call(start: start, limit: _pageSize);
      if (res.isSuccess) {
        final fetched = res.data ?? [];
        if (reset) {
          _users = fetched;
        } else {
          _users = [..._users, ...fetched];
        }
        _hasMore = fetched.length >= _pageSize;
        if (_hasMore) _page += 1;
      } else {
        _error = res.error;
      }
    } catch (e) {
      _error = mapException(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}