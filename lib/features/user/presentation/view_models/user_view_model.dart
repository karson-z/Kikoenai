import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:name_app/features/user/data/services/user_repository.dart';
import '../../data/models/user_model.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/core/common/errors.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository = GetIt.I<UserRepository>();
  bool _loading = false;
  Failure? _error;
  UserModel? _user;

  bool get loading => _loading;
  Failure? get error => _error;
  UserModel? get user => _user;

  Future<void> getUser() async {
    _loading = true;
    _error = null;
    try {
      notifyListeners();
      final Result<UserModel> res = await _userRepository.getUsers();
      if (res.isSuccess) {
        _user = res.data;
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
