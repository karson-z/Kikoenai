import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///lyric model
class LyricsReaderModel {
  List<LyricsLineModel> lyrics = [];
}
extension LyricsListExtension on List<LyricsLineModel> {
  /// 获取当前播放时间对应的歌词行索引
  int getCurrentLine(int progress) {
    if (isEmpty) return 0;

    // 二分查找优化版 (假设你的列表已排序)
    int left = 0;
    int right = length - 1;

    while (left <= right) {
      int mid = left + ((right - left) >> 1);
      int midTime = this[mid].startTime ?? 0;

      if (midTime <= progress) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    // 此时 right 指向的是最后一个满足 startTime <= progress 的元素

    // 额外检查：VTT 格式可能有明确的 endTime，如果 progress 超过了 endTime，
    // 在某些 UI 需求下可能需要返回 -1 (表示当前没有任何歌词显示)
    // 但为了保持你的原始逻辑（保持显示上一句），这里直接返回 right。

    return right < 0 ? 0 : right;
  }
}


///lyric line model
class LyricsLineModel {
  String? mainText;
  String? extText;
  int? startTime;
  int? endTime;

  //绘制信息
  LyricDrawInfo? drawInfo;

  bool get hasExt => extText?.isNotEmpty == true;

  bool get hasMain => mainText?.isNotEmpty == true;

}

///lyric draw model
class LyricDrawInfo {
  double get otherMainTextHeight => otherMainTextPainter?.height ?? 0;

  double get otherExtTextHeight => otherExtTextPainter?.height ?? 0;

  double get playingMainTextHeight => playingMainTextPainter?.height ?? 0;

  double get playingExtTextHeight => playingExtTextPainter?.height ?? 0;
  TextPainter? otherMainTextPainter;
  TextPainter? otherExtTextPainter;
  TextPainter? playingMainTextPainter;
  TextPainter? playingExtTextPainter;
  List<LyricInlineDrawInfo> inlineDrawList = [];
}

class LyricInlineDrawInfo {
  int number = 0;
  String raw = "";
  double width = 0;
  double height = 0;
  Offset offset = Offset.zero;
}


extension LyricsReaderModelExt on LyricsReaderModel? {
  get isNullOrEmpty => this?.lyrics == null || this!.lyrics.isEmpty;
}
