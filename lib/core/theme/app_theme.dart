import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  /// 亮色主题
  static ThemeData light(Color seed) => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // 背景白色
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          primary: seed,
        ),
        textTheme: GoogleFonts.notoSansScTextTheme()
            .apply(bodyColor: Colors.black, displayColor: Colors.black),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // AppBar 背景也白色
          foregroundColor: seed,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.kPadding,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.kRadius),
            ),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: Colors.transparent,
          selectedIconTheme: IconThemeData(color: seed),
          backgroundColor: Colors.transparent,
          unselectedIconTheme: const IconThemeData(color: Colors.black54),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, // 背景白色
          elevation: 1.5,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withAlpha(70),
        ),
      );

  /// 暗色主题
  static ThemeData dark(Color seed) => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black, // 背景黑色
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          primary: seed,
        ),
        textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black, // AppBar 背景黑色
          foregroundColor: seed,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.kPadding,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.kRadius),
            ),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: seed.withOpacity(0.2),
          selectedIconTheme: IconThemeData(color: seed),
          unselectedIconTheme: const IconThemeData(color: Colors.white54),
          labelType: NavigationRailLabelType.all,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E), // 深色背景
          elevation: 1.5,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
      );
}
