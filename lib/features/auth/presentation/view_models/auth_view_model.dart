import 'package:flutter/foundation.dart';
import '../../../../core/utils/validators.dart';

class AuthViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Local form validation using utils
      if (!isValidEmail(email)) {
        throw Exception('邮箱格式不正确');
      }
      if (!isValidPassword(password)) {
        throw Exception('密码长度至少6位');
      }

      // Simulate a network request
      await Future.delayed(const Duration(seconds: 1));
      // Success: do nothing for demo
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}