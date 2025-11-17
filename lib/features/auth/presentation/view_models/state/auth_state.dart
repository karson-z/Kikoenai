import 'package:equatable/equatable.dart';
import 'package:name_app/features/user/data/models/user.dart';



class AuthState extends Equatable {
  final User? currentUser;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.currentUser,
    this.token,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });
  AuthState copyWith({
    User? currentUser,
    String? token,
    String? host,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  @override
  List<Object?> get props =>
      [currentUser, token, isLoading, error, isLoggedIn];
}