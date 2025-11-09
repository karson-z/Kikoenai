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

    if (modeStr != null) _mode = _parseMode(modeStr);
    if (seed != null) _seedColor = Color(seed);

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
      _recentSeeds.map((c) => c.toARGB32().toString()).toList(),
    );
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    _persist();
    notifyListeners();
  }

  void toggleLightDark() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist();
    notifyListeners();
  }

  void useSystem() {
    _mode = ThemeMode.system;
    _persist();
    notifyListeners();
  }

  void setSeedColor(Color color, {bool preview = false}) {
    _seedColor = color;
    if (!preview) _updateRecentSeeds(color);
    _persist();
    notifyListeners();
  }

  void _updateRecentSeeds(Color color) {
    final list = List<Color>.from(_recentSeeds);
    list.removeWhere((c) => c.toARGB32() == color.toARGB32());
    list.insert(0, color);
    const maxLen = 8;
    if (list.length > maxLen) list.removeRange(maxLen, list.length);
    _recentSeeds = list;
  }

  ThemeMode _parseMode(String s) {
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
