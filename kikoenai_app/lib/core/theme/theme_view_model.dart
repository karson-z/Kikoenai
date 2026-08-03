import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_constants.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/theme/app_font_preset.dart';

class ThemeState {
  final ThemeMode mode;
  final Color seedColor;
  final List<Color> recentSeeds;
  final AppFontPreset fontPreset;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.seedColor = Colors.blue,
    this.recentSeeds = const [],
    this.fontPreset = AppFontPreset.notoSansSc,
  });

  ThemeState copyWith({
    ThemeMode? mode,
    Color? seedColor,
    List<Color>? recentSeeds,
    AppFontPreset? fontPreset,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      seedColor: seedColor ?? this.seedColor,
      recentSeeds: recentSeeds ?? this.recentSeeds,
      fontPreset: fontPreset ?? this.fontPreset,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _keyMode = 'theme_mode';
  static const _keySeed = 'theme_seed_color';
  static const _keyRecent = 'theme_recent_seeds';
  static const _keyFontPreset = StorageKeys.themeFontPreset;

  Box<dynamic> get settingBox => AppStorage.settingsBox;

  @override
  ThemeState build() {
    final modeStr = settingBox.get(_keyMode) as String?;
    final seed = settingBox.get(_keySeed) as int?;
    final recent = settingBox.get(_keyRecent) as List<dynamic>? ?? [];
    final fontPresetKey = settingBox.get(_keyFontPreset) as String?;

    final mode = _parseMode(modeStr);
    final seedColor = seed != null ? Color(seed) : Colors.blue;
    final recentSeeds = recent
        .whereType<int>()
        .map((v) => Color(v))
        .toList(growable: false);
    final fontPreset = AppFontPreset.fromStorageKey(fontPresetKey);

    return ThemeState(
      mode: mode,
      seedColor: seedColor,
      recentSeeds: recentSeeds,
      fontPreset: fontPreset,
    );
  }

  void _persist(ThemeState s) {
    settingBox.put(_keyMode, s.mode.name);
    settingBox.put(_keySeed, s.seedColor.toARGB32());
    settingBox.put(_keyRecent, s.recentSeeds.map((c) => c.toARGB32()).toList());
    settingBox.put(_keyFontPreset, s.fontPreset.storageKey);
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _persist(state);
  }

  void toggleLightDark() {
    final newMode = state.mode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setMode(newMode);
  }

  void useSystem() {
    setMode(ThemeMode.system);
  }

  void setSeedColor(Color color, {bool preview = false}) {
    var recent = state.recentSeeds;

    if (!preview) {
      recent = List.of(recent);
      recent.removeWhere((c) => c.toARGB32() == color.toARGB32());
      recent.insert(0, color);
      if (recent.length > 8) recent = recent.sublist(0, 8);
    }

    state = state.copyWith(seedColor: color, recentSeeds: recent);

    if (!preview) _persist(state);
  }

  void setFontPreset(AppFontPreset fontPreset) {
    state = state.copyWith(fontPreset: fontPreset);
    _persist(state);
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

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

final platformBrightnessProvider = Provider<Brightness>((ref) {
  return MediaQuery.platformBrightnessOf(
    AppConstants.rootNavigatorKey.currentContext!,
  );
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
