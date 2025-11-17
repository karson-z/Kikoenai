import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:name_app/core/common/global_exception.dart';
import 'package:name_app/core/common/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'errors.dart';
final sharedPreferencesServiceProvider =
Provider<SharedPreferencesService>((ref) {
  return SharedPreferencesService();
});
class SharedPreferencesService {
  SharedPreferencesService._internal(); // 私有构造

  static final SharedPreferencesService _instance =
  SharedPreferencesService._internal();

  factory SharedPreferencesService() => _instance;

  final _log = Logger('SharedPreferencesService');

  static SharedPreferences? _prefs;

  /// 确保初始化 SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Result<String?>> fetchToken() async {
    try {
      final token = _prefs?.getString(AppConstants.tokenKey);
      _log.finer('Got token from SharedPreferences');
      return Result.success(data: token);
    } on Exception catch (e,st) {
      _log.warning('Failed to get token', e);
      throw GlobalException('Failed to get token',stackTrace: st);
    }
  }

  Future<Result<void>> saveToken(String? token) async {
    try {
      if (token == null) {
        _log.finer('Removed token');
        await _prefs?.remove(AppConstants.tokenKey);
      } else {
        _log.finer('Replaced token');
        await _prefs?.setString(AppConstants.tokenKey, token);
      }
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to set token', e);
      throw GlobalException('Failed to set token');
    }
  }

  Future<Result<void>> removeToken() async {
    try {
      await _prefs?.remove(AppConstants.tokenKey);
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to remove token', e);
      throw GlobalException('Failed to remove token');
    }
  }

  Future<Result<void>> removeAll() async {
    try {
      await _prefs?.remove(AppConstants.tokenKey);
      return Result.success();
    } on Exception catch (e) {
      _log.warning('Failed to remove all', e);
      throw GlobalException('Failed to remove all');
    }
  }

  Future<void> checkSize({int warnThresholdKB = 512}) async {
    if (_prefs == null) return;
    final all = _prefs!.getKeys();

    int totalBytes = 0;
    final Map<String, int> keySizes = {};

    for (final key in all) {
      final value = _prefs!.get(key);
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
