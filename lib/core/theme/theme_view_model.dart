import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme state
class ThemeState {
  final ThemeMode mode;
  final Color seedColor;
  final List<Color> recentSeeds;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.seedColor = Colors.blue,
    this.recentSeeds = const [],
  });

  ThemeState copyWith({
    ThemeMode? mode,
    Color? seedColor,
    List<Color>? recentSeeds,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      seedColor: seedColor ?? this.seedColor,
      recentSeeds: recentSeeds ?? this.recentSeeds,
    );
  }
}

/// Notifier，同步版本
class ThemeNotifier extends Notifier<ThemeState> {
  static const _keyMode = 'theme_mode';
  static const _keySeed = 'theme_seed_color';
  static const _keyRecent = 'theme_recent_seeds';

  late SharedPreferences _prefs;

  @override
  ThemeState build() {
    // 默认返回一个同步可用的初始 state
    _load(); // 异步加载并覆盖 state，不影响同步使用
    return const ThemeState();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final modeStr = _prefs.getString(_keyMode);
    final seed = _prefs.getInt(_keySeed);
    final recent = _prefs.getStringList(_keyRecent) ?? [];

    final mode = _parseMode(modeStr);
    final seedColor = seed != null ? Color(seed) : Colors.blue;

    final recentSeeds = recent
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .map((v) => Color(v))
        .toList(growable: false);

    state = ThemeState(
      mode: mode,
      seedColor: seedColor,
      recentSeeds: recentSeeds,
    );
  }

  /// 持久化
  Future<void> _persist(ThemeState s) async {
    await _prefs.setString(_keyMode, s.mode.name);
    await _prefs.setInt(_keySeed, s.seedColor.value);
    await _prefs.setStringList(
      _keyRecent,
      s.recentSeeds.map((c) => c.value.toString()).toList(),
    );
  }

  // 切换模式
  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _persist(state);
  }

  Future<void> toggleLightDark() async {
    final newMode =
    state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(newMode);
  }

  Future<void> useSystem() async {
    await setMode(ThemeMode.system);
  }

  Future<void> setSeedColor(Color color, {bool preview = false}) async {
    var recent = state.recentSeeds;

    if (!preview) {
      recent = List.of(recent);
      recent.removeWhere((c) => c.value == color.value);
      recent.insert(0, color);
      if (recent.length > 8) recent = recent.sublist(0, 8);
    }

    state = state.copyWith(seedColor: color, recentSeeds: recent);

    if (!preview) await _persist(state);
  }

  ThemeMode _parseMode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

/// Provider（同步 Notifier）
final themeNotifierProvider =
NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
final platformBrightnessProvider = Provider<Brightness>((ref) {
  return MediaQuery.platformBrightnessOf(AppConstants.rootNavigatorKey.currentContext!);
});
final explicitDarkModeProvider = Provider<bool>((ref) {
  final theme = ref.watch(themeNotifierProvider);
  final systemBrightness = ref.watch(platformBrightnessProvider);

  switch (theme.mode) {
    case ThemeMode.light:
      return false;
    case ThemeMode.dark:
      return true;
    case ThemeMode.system:
      return systemBrightness == Brightness.dark;
  }
});