import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFontPreset {
  system(storageKey: 'system', label: '系统默认', description: '跟随设备字体，兼顾平台一致性'),
  notoSansSc(
    storageKey: 'noto_sans_sc',
    label: 'Noto Sans SC',
    description: '清晰中性，适合界面正文和长时间阅读',
  ),
  notoSerifSc(
    storageKey: 'noto_serif_sc',
    label: 'Noto Serif SC',
    description: '衬线风格更明显，阅读层次感更强',
  ),
  zcoolXiaoWei(
    storageKey: 'zcool_xiaowei',
    label: 'ZCOOL XiaoWei',
    description: '更有个性，适合偏展示感的整体风格',
  );

  const AppFontPreset({
    required this.storageKey,
    required this.label,
    required this.description,
  });

  final String storageKey;
  final String label;
  final String description;

  static AppFontPreset fromStorageKey(String? key) {
    return AppFontPreset.values.firstWhere(
      (preset) => preset.storageKey == key,
      orElse: () => AppFontPreset.notoSansSc,
    );
  }

  String? get fontFamily {
    switch (this) {
      case AppFontPreset.system:
        return null;
      case AppFontPreset.notoSansSc:
        return GoogleFonts.notoSansSc().fontFamily;
      case AppFontPreset.notoSerifSc:
        return GoogleFonts.notoSerifSc().fontFamily;
      case AppFontPreset.zcoolXiaoWei:
        return GoogleFonts.zcoolXiaoWei().fontFamily;
    }
  }

  TextTheme applyToTextTheme(TextTheme baseTextTheme) {
    switch (this) {
      case AppFontPreset.system:
        return baseTextTheme;
      case AppFontPreset.notoSansSc:
        return GoogleFonts.notoSansScTextTheme(baseTextTheme);
      case AppFontPreset.notoSerifSc:
        return GoogleFonts.notoSerifScTextTheme(baseTextTheme);
      case AppFontPreset.zcoolXiaoWei:
        return GoogleFonts.zcoolXiaoWeiTextTheme(baseTextTheme);
    }
  }

  TextStyle applyToTextStyle(TextStyle? baseStyle) {
    switch (this) {
      case AppFontPreset.system:
        return baseStyle ?? const TextStyle();
      case AppFontPreset.notoSansSc:
        return GoogleFonts.notoSansSc(textStyle: baseStyle);
      case AppFontPreset.notoSerifSc:
        return GoogleFonts.notoSerifSc(textStyle: baseStyle);
      case AppFontPreset.zcoolXiaoWei:
        return GoogleFonts.zcoolXiaoWei(textStyle: baseStyle);
    }
  }
}
