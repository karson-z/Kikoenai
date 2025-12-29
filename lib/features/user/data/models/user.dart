import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

// 2. 指定生成的 Adapter 文件名
part 'user.g.dart';

@HiveType(typeId: 11) // 3. 设置唯一的 typeId
class User extends Equatable {

  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? password;

  @HiveField(3)
  final String? token;

  @HiveField(4)
  final DateTime? lastUpdateTime;

  @HiveField(5)
  final bool loggedIn;

  @HiveField(6)
  final String? group;

  @HiveField(7)
  final String? email;

  @HiveField(8)
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
    // 你的原始逻辑保持不变
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