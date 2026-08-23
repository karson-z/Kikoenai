import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/core/constants/type_ids.dart';

part 'lyric_model.g.dart';

@HiveType(typeId: TypeIds.lyricConfig) // 确保 ID 不重??
class LyricConfigModel {
  // === 字体大小细分 ===
  @HiveField(0)
  final double mainFontSize; // 主歌词大??(默认 25)

  @HiveField(1)
  final double transFontSize; // 翻译歌词大小 (默认 15)

  @HiveField(2)
  final double activeFontSize; // 高亮??正在播放)的大??(默认 30)

  @HiveField(3)
  final double lineGap; // 普通行之间的间??(默认 24)

  @HiveField(4)
  final double translationGap; // 主歌词与翻译歌词之间的间??(默认 6)

  const LyricConfigModel({
    this.mainFontSize = 25.0,
    this.transFontSize = 15.0,
    this.activeFontSize = 30.0,
    this.lineGap = 24.0,
    this.translationGap = 6.0,
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
