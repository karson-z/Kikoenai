import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static const _keyMode = 'theme_mode';
  static const _keySeed = 'theme_seed_color';
  static const _keyRecent = 'theme_recent_seeds';

  ThemeMode _mode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  List<Color> _recentSeeds = const [];

  ThemeMode get themeMode => _mode;
  Color get seedColor => _seedColor;
  List<Color> get recentSeedColors => List.unmodifiable(_recentSeeds);

  ThemeViewModel() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_keyMode);
    final seed = prefs.getInt(_keySeed);
    final recent = prefs.getStringList(_keyRecent) ?? const [];
    if (modeStr != null) {
      _mode = _parseMode(modeStr);
    }
    if (seed != null) {
      _seedColor = Color(seed);
    }
    _recentSeeds = recent
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .map((v) => Color(v))
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, _mode.name);
    await prefs.setInt(_keySeed, _seedColor.value);
    await prefs.setStringList(
      _keyRecent,
      _recentSeeds.map((c) => c.value.toString()).toList(),
    );
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    _persist();
    notifyListeners();
  }

  void toggleLightDark() {
    if (_mode == ThemeMode.dark) {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    _persist();
    notifyListeners();
  }

  void useSystem() {
    _mode = ThemeMode.system;
    _persist();
    notifyListeners();
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    _updateRecentSeeds(color);
    _persist();
    notifyListeners();
  }

  void _updateRecentSeeds(Color color) {
    final list = List<Color>.from(_recentSeeds);
    // Remove duplicates
    list.removeWhere((c) => c.value == color.value);
    // Insert at front
    list.insert(0, color);
    // Cap length
    const maxLen = 8;
    if (list.length > maxLen) {
      list.removeRange(maxLen, list.length);
    }
    _recentSeeds = list;
  }

  ThemeMode _parseMode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}