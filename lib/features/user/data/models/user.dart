import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String name;
  final String? password;
  final String? token;
  final DateTime? lastUpdateTime;
  final bool loggedIn;
  final String? group;
  final String? email;
  final String? recommenderUuid;

  const User({
    this.id,
    required this.name,
    this.password,
    this.token,
    this.lastUpdateTime,
    this.loggedIn = false,
    this.group,
    this.email,
    this.recommenderUuid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json;

    return User(
      name: userJson['name'] as String? ?? '',
      loggedIn: userJson['loggedIn'] as bool? ?? false,
      group: userJson['group'] as String?,
      email: userJson['email'] as String?,
      recommenderUuid: userJson['recommenderUuid'] as String?,
      password: json['password'] as String?,
      token: json['token'] as String?,
      id: json['id'] as int?,
      lastUpdateTime: json['lastUpdateTime'] != null
          ? DateTime.parse(json['lastUpdateTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'token': token,
      'lastUpdateTime': lastUpdateTime?.toIso8601String(),
      'loggedIn': loggedIn,
      'group': group,
      'email': email,
      'recommenderUuid': recommenderUuid,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? password,
    String? token,
    DateTime? lastUpdateTime,
    bool? loggedIn,
    String? group,
    String? email,
    String? recommenderUuid,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      token: token ?? this.token,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      loggedIn: loggedIn ?? this.loggedIn,
      group: group ?? this.group,
      email: email ?? this.email,
      recommenderUuid: recommenderUuid ?? this.recommenderUuid,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    password,
    token,
    lastUpdateTime,
    loggedIn,
    group,
    email,
    recommenderUuid,
  ];
}
