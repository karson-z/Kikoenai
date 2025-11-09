import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:name_app/core/constants/app_constants.dart';
import 'package:name_app/core/common/errors.dart';
import 'package:name_app/core/common/result.dart';
import 'package:name_app/features/user/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  final _log = Logger('SharedPreferencesService');

  Future<Result<String?>> fetchToken() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      _log.finer('Got token from SharedPreferences');
      return Result.success(
          data: sharedPreferences.getString(AppConstants.tokenKey));
    } on Exception catch (e) {
      _log.warning('Failed to get token', e);
      return Result.failure(
          error: ServerFailure('Failed to get token', code: 401));
    }
  }

  Future<Result<void>> saveToken(String? token) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      if (token == null) {
        _log.finer('Removed token');
        await sharedPreferences.remove(AppConstants.tokenKey);
      } else {
        _log.finer('Replaced token');
        await sharedPreferences.setString(AppConstants.tokenKey, token);
      }
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to set token', e);
      return Result.failure(
          error: ServerFailure('save token failed', code: 401));
    }
  }

  Future<Result<void>> saveUserInfo(UserModel user) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(
          AppConstants.userInfoKey, jsonEncode(user.toJson()));
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to set token', e);
      return Result.failure(
          error: ServerFailure('save userInfo failed', code: 401));
    }
  }

  Future<Result<UserModel>> fetchUserInfo() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      _log.finer('Got token from SharedPreferences');
      final userInfo = sharedPreferences.getString(AppConstants.userInfoKey);
      return Result.success(
          data: userInfo != null
              ? UserModel.fromJson(jsonDecode(userInfo))
              : null); // 从 JSON 字符串恢复 UserVo 对象
    } on Exception catch (e) {
      _log.warning('Failed to get userInfo', e);
      return Result.failure(
          error: ServerFailure('Failed to get userInfo', code: 401));
    }
  }

  Future<Result<void>> removeUserInfo() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove(AppConstants.userInfoKey);
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to remove userInfo', e);
      return Result.failure(
          error: ServerFailure('remove userInfo failed', code: 401));
    }
  }

  Future<Result<void>> removeToken() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove(AppConstants.tokenKey);
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to remove token', e);
      return Result.failure(
          error: ServerFailure('remove token failed', code: 401));
    }
  }

  Future<Result<void>> removeAll() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove(AppConstants.tokenKey);
      await sharedPreferences.remove(AppConstants.userInfoKey);
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to remove all', e);
      return Result.failure(
          error: ServerFailure('remove all failed', code: 401));
    }
  }

  static Future<void> checkSize({int warnThresholdKB = 512}) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getKeys();

    int totalBytes = 0;
    final Map<String, int> keySizes = {};

    for (final key in all) {
      final value = prefs.get(key);
      final encoded = utf8.encode(jsonEncode(value));
      final size = encoded.length;
      keySizes[key] = size;
      totalBytes += size;
    }

    final totalKB = totalBytes / 1024;
    final warn = totalKB > warnThresholdKB;

    if (kDebugMode) {
      debugPrint('📊 SharedPreferences 总大小: ${totalKB.toStringAsFixed(2)} KB');
      debugPrint('----------------------------');
      for (final entry in keySizes.entries) {
        debugPrint('🔸 ${entry.key}: ${entry.value} bytes');
      }
      debugPrint('----------------------------');
      if (warn) {
        debugPrint(
            '⚠️ 警告：SharedPreferences 超过 ${warnThresholdKB}KB，建议清理或改用数据库。');
      } else {
        debugPrint('✅ SharedPreferences 容量正常。');
      }
    }
  }
}
