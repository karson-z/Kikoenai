import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme state
class ThemeState {
  final ThemeMode _mode;
  final Color _seedColor;
  final List<Color> _recentSeeds;

  const ThemeState({
    ThemeMode mode = ThemeMode.system,
    Color seedColor = Colors.blue,
    List<Color> recentSeeds = const [],
  })  : _mode = mode,
        _seedColor = seedColor,
        _recentSeeds = recentSeeds;

  ThemeState copyWith({
    ThemeMode? mode,
    Color? seedColor,
    List<Color>? recentSeeds,
  }) {
    return ThemeState(
      mode: mode ?? _mode,
      seedColor: seedColor ?? _seedColor,
      recentSeeds: recentSeeds ?? _recentSeeds,
    );
  }

  // Getter 方法
  ThemeMode get mode => _mode;
  Color get seedColor => _seedColor;
  List<Color> get recentSeeds => List.unmodifiable(_recentSeeds);
}


/// Riverpod AsyncNotifier 管理主题
class ThemeNotifier extends AsyncNotifier<ThemeState> {
  static const _keyMode = 'theme_mode';
  static const _keySeed = 'theme_seed_color';
  static const _keyRecent = 'theme_recent_seeds';

  @override
  Future<ThemeState> build() async {
    // 初始化，加载 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_keyMode);
    final seed = prefs.getInt(_keySeed);
    final recent = prefs.getStringList(_keyRecent) ?? const [];

    final mode = _parseMode(modeStr);
    final seedColor = seed != null ? Color(seed) : Colors.blue;
    final recentSeeds = recent
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .map((v) => Color(v))
        .toList(growable: false);

    return ThemeState(
      mode: mode,
      seedColor: seedColor,
      recentSeeds: recentSeeds,
    );
  }

  Future<void> _persist(ThemeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, state.mode.name);
    await prefs.setInt(_keySeed, state.seedColor.value);
    await prefs.setStringList(
      _keyRecent,
      state.recentSeeds.map((c) => c.value.toString()).toList(),
    );
  }

  // 切换模式
  Future<void> setMode(ThemeMode mode) async {
    final newState = state.value!.copyWith(mode: mode);
    state = AsyncData(newState);
    await _persist(newState);
  }

  Future<void> toggleLightDark() async {
    final current = state.value!;
    final newMode =
    current.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(newMode);
  }

  Future<void> useSystem() async {
    await setMode(ThemeMode.system);
  }

  Future<void> setSeedColor(Color color, {bool preview = false}) async {
    final current = state.value!;
    var newRecent = current.recentSeeds;
    if (!preview) {
      newRecent = List<Color>.from(current.recentSeeds);
      newRecent.removeWhere((c) => c.value == color.value);
      newRecent.insert(0, color);
      if (newRecent.length > 8) newRecent = newRecent.sublist(0, 8);
    }

    final newState =
    current.copyWith(seedColor: color, recentSeeds: newRecent);
    state = AsyncData(newState);
    if (!preview) await _persist(newState);
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

/// Riverpod provider
final themeNotifierProvider =
AsyncNotifierProvider<ThemeNotifier, ThemeState>(() => ThemeNotifier());
