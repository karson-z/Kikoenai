import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';

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

class ThemeNotifier extends Notifier<ThemeState> {
  static const _keyMode = 'theme_mode';
  static const _keySeed = 'theme_seed_color';
  static const _keyRecent = 'theme_recent_seeds';

  Box<dynamic> get settingBox => AppStorage.settingsBox;

  @override
  ThemeState build() {
    final modeStr = settingBox.get(_keyMode) as String?;
    final seed = settingBox.get(_keySeed) as int?;
    final recent = settingBox.get(_keyRecent) as List<dynamic>? ?? [];

    final mode = _parseMode(modeStr);
    final seedColor = seed != null ? Color(seed) : Colors.blue;
    final recentSeeds = recent
        .whereType<int>()
        .map((v) => Color(v))
        .toList(growable: false);

    return ThemeState(
      mode: mode,
      seedColor: seedColor,
      recentSeeds: recentSeeds,
    );
  }

  void _persist(ThemeState s) {
    settingBox.put(_keyMode, s.mode.name);
    settingBox.put(_keySeed, s.seedColor.value);
    settingBox.put(_keyRecent, s.recentSeeds.map((c) => c.value).toList());
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _persist(state);
  }

  void toggleLightDark() {
    final newMode =
    state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setMode(newMode);
  }

  void useSystem() {
    setMode(ThemeMode.system);
  }

  void setSeedColor(Color color, {bool preview = false}) {
    var recent = state.recentSeeds;

    if (!preview) {
      recent = List.of(recent);
      recent.removeWhere((c) => c.value == color.value);
      recent.insert(0, color);
      if (recent.length > 8) recent = recent.sublist(0, 8);
    }

    state = state.copyWith(seedColor: color, recentSeeds: recent);

    if (!preview) _persist(state);
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