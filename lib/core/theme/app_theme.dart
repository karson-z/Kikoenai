import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'app_color.dart';
class AppTheme {
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
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 1.5,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.lightShadow,
    ),
  );

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
      indicatorColor: seed.withOpacity(0.2),
      selectedIconTheme: IconThemeData(color: seed),
      unselectedIconTheme:
      const IconThemeData(color: AppColors.darkTextSecondary),
      labelType: NavigationRailLabelType.all,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 1.5,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.darkShadow,
    ),
  );
}
