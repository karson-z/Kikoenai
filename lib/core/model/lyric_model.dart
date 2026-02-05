import 'package:hive_ce/hive.dart';

part 'lyric_model.g.dart';

@HiveType(typeId: 6) // 确保 ID 不重复
class LyricConfigModel {
  // === 字体大小细分 ===
  @HiveField(0)
  final double mainFontSize;       // 主歌词大小 (默认 18)

  @HiveField(1)
  final double transFontSize;      // 翻译歌词大小 (默认 14)

  @HiveField(2)
  final double activeFontSize;     // 高亮行(正在播放)的大小 (默认 22)

  @HiveField(3)
  final double lineGap;            // 普通行之间的间距 (默认 15)

  @HiveField(4)
  final double translationGap;     // 主歌词与翻译歌词之间的间距 (默认 8)

  const LyricConfigModel({
    this.mainFontSize = 18.0,
    this.transFontSize = 12.0,
    this.activeFontSize = 22.0,
    this.lineGap = 35.0,
    this.translationGap = 5.0,
  });

  // 用于更新状态的 CopyWith
  LyricConfigModel copyWith({
    double? mainFontSize,
    double? transFontSize,
    double? activeFontSize,
    double? lineGap,
    double? translationGap,
  }) {
    return LyricConfigModel(
      mainFontSize: mainFontSize ?? this.mainFontSize,
      transFontSize: transFontSize ?? this.transFontSize,
      activeFontSize: activeFontSize ?? this.activeFontSize,
      lineGap: lineGap ?? this.lineGap,
      translationGap: translationGap ?? this.translationGap,
    );
  }
}
