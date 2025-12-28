import 'package:equatable/equatable.dart';
import '../../../../user/data/models/user.dart';

class AuthState extends Equatable {
  final User? currentUser;
  final String? token;

  const AuthState({
    this.currentUser,
    this.token,
  });

  // 👇 使用 getter 自动计算登录状态，确保单一真实数据源
  bool get isLoggedIn => token != null && token!.isNotEmpty;

  AuthState copyWith({
    User? currentUser,
    String? token,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [currentUser, token];
}