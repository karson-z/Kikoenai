import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'app_color.dart';

class AppTheme {
  // 浅色主题 (light)
  static ThemeData light(Color seed) => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
    ),
    textTheme: GoogleFonts.notoSansScTextTheme()
        .apply(bodyColor: AppColors.lightText, displayColor: AppColors.lightText),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: seed,
      surfaceTintColor: AppColors.transparent,
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
        foregroundColor: AppColors.lightBackground,
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
      indicatorColor: AppColors.transparent,
      selectedIconTheme: IconThemeData(color: seed),
      backgroundColor: AppColors.transparent,
      unselectedIconTheme:
      IconThemeData(color: AppColors.lightTextSecondary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,

      // 🚀 核心优化：移除 hover/splash 时的灰色背景
      // 设置 overlayColor 为透明，禁用所有交互反馈的背景色。
      overlayColor: WidgetStateProperty.all(Colors.transparent),

      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: seed.withAlpha(150),
            size: 24,
          );
        }
        return const IconThemeData(
          color: Colors.grey,
          size: 22,
        );
      }),
      // 完善 labelTextStyle 逻辑，保持样式一致
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: seed.withAlpha(150),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          );
        }
        return const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 1.5,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.lightShadow,
    ),
  );

  // 深色主题 (dark)
  static ThemeData dark(Color seed) => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: seed,
    ),
    textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: AppColors.darkText, displayColor: AppColors.darkText),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: seed,
      surfaceTintColor: AppColors.transparent,
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
        foregroundColor: AppColors.darkText,
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
      indicatorColor: seed.withAlpha(20),
      selectedIconTheme: IconThemeData(color: seed),
      unselectedIconTheme:
      const IconThemeData(color: AppColors.darkTextSecondary),
      labelType: NavigationRailLabelType.all,
    ),
    navigationBarTheme: NavigationBarThemeData(
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,

      // 设置 overlayColor 为透明，禁用所有交互反馈的背景色。
      overlayColor: WidgetStateProperty.all(Colors.transparent),

      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: seed,
            size: 24,
          );
        }
        return const IconThemeData(
          color: Colors.grey,
          size: 22,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 1.5,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.darkShadow,
    ),
  );
}