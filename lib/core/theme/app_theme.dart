import 'package:flutter/cupertino.dart'; // 引入 Cupertino 以支持 override
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'app_color.dart';

class AppTheme {
  // ----------------- 浅色主题 (Light) -----------------
  static ThemeData light(Color seed) => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // 1. 颜色方案
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      surface: AppColors.lightCard, // Material3 中 surface 通常对应卡片色
      onSurface: AppColors.lightText,
      outline: AppColors.lightDivider, // 边框颜色
    ),

    // 2. 文本主题
    textTheme: GoogleFonts.notoSansScTextTheme()
        .apply(bodyColor: AppColors.lightText, displayColor: AppColors.lightText),

    // 3. 关键：适配 Cupertino 组件 (滚轮选择器) 的颜色
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      textTheme: CupertinoTextThemeData(
        dateTimePickerTextStyle: TextStyle(color: Colors.black, fontSize: 22),
        pickerTextStyle: TextStyle(color: Colors.black, fontSize: 20),
      ),
    ),

    // 4. BottomSheet 全局样式 (对应你的弹窗背景)
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightGroupedBackground, // 使用浅灰底色
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // 5. 分割线样式
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 1,
    ),

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
        foregroundColor: Colors.white,
        elevation: 0,
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
      unselectedIconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
    ),

    navigationBarTheme: NavigationBarThemeData(
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      backgroundColor: Colors.white,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: seed.withAlpha(150), size: 24);
        }
        return const IconThemeData(color: Colors.grey, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: seed.withAlpha(150), fontSize: 12, fontWeight: FontWeight.bold);
        }
        return const TextStyle(color: Colors.grey, fontSize: 12);
      }),
    ),

    cardTheme: const CardThemeData(
      color: AppColors.lightCard,
      elevation: 0, // 扁平化风格通常 elevation 较低
      margin: EdgeInsets.zero,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.lightShadow,
    ),
  );

  // ----------------- 深色主题 (Dark) -----------------
  static ThemeData dark(Color seed) => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // 1. 颜色方案
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: seed,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkText,
      outline: AppColors.darkDivider,
    ),

    // 2. 文本主题
    textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: AppColors.darkText, displayColor: AppColors.darkText),

    // 3. 关键：适配 Cupertino 组件 (滚轮选择器) 的颜色
    // 这会让 CupertinoPicker 知道现在是暗色模式，从而把字变成白色
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      textTheme: CupertinoTextThemeData(
        dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        pickerTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
    ),

    // 4. BottomSheet 全局样式
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkGroupedBackground, // 使用深黑底色
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // 5. 分割线样式
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),

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
        elevation: 0,
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
      indicatorColor: seed.withAlpha(50),
      selectedIconTheme: IconThemeData(color: seed),
      backgroundColor: AppColors.transparent,
      unselectedIconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      labelType: NavigationRailLabelType.all,
    ),

    navigationBarTheme: NavigationBarThemeData(
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      backgroundColor: Colors.black45,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: seed, size: 24);
        }
        return const IconThemeData(color: Colors.grey, size: 22);
      }),
    ),

    cardTheme: const CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.darkShadow,
    ),
  );
}