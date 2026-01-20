import 'dart:convert';

import '../../model/lyric_model.dart';
enum LyricFormat { lrc, vtt, unknown }
/// 解析格式工厂
class LyricsParserFactory {
  static LyricsParse create(String content, LyricFormat format) {
    switch (format) {
      case LyricFormat.lrc:
        return ParserLrc(content);
      case LyricFormat.vtt:
        return ParserVtt(content);
      default:
      // 默认尝试当作 lrc 处理，或者抛出异常
        return ParserLrc(content);
    }
  }

  /// 简单的辅助方法，通过文件名后缀判断
  static LyricFormat guessFormat(String fileName) {
    if (fileName.endsWith('.vtt')) return LyricFormat.vtt;
    if (fileName.endsWith('.lrc')) return LyricFormat.lrc;
    return LyricFormat.unknown;
  }
}

abstract class LyricsParse {
  String lyric;

  LyricsParse(this.lyric);

  ///call this method parse
  List<LyricsLineModel> parseLines({bool isMain = true});

  ///verify [lyric] is matching
  bool isOK() => true;
}

class ParserLrc extends LyricsParse {

  //  这里的正则用于提取所有的时间标签
  RegExp timeRegex = RegExp(r"\[(\d{2}):(\d{2})\.(\d{2,3})\]");

  ParserLrc(String lyric) : super(lyric);

  @override
  List<LyricsLineModel> parseLines({bool isMain = true}) {

    var lines = const LineSplitter().convert(lyric);

    if (lines.isEmpty) return [];

    List<LyricsLineModel> lineList = [];

    for (var line in lines) {
      // 查找所有的匹配项（解决一行多时间标签的问题）
      Iterable<RegExpMatch> matches = timeRegex.allMatches(line);

      if (matches.isEmpty) {
        continue;
      }


      var realLyrics = line.replaceAll(timeRegex, "").trim();

      // 处理特殊字符
      if (realLyrics == "//") realLyrics = "";

      // 4. 为每一个时间标签生成一个歌词对象
      for (var match in matches) {
        var startTime = _parseTimestamp(match);

        var lineModel = LyricsLineModel()
          ..startTime = startTime;

        if (isMain) {
          lineModel.mainText = realLyrics;
        } else {
          lineModel.extText = realLyrics;
        }
        lineList.add(lineModel);
      }
    }

    lineList.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

    return lineList;
  }

  /// 直接从正则匹配结果中解析时间，性能更高
  int _parseTimestamp(RegExpMatch match) {

    int minute = int.parse(match.group(1)!);
    int second = int.parse(match.group(2)!);
    String millisecondStr = match.group(3)!;

    int millisecond = int.parse(millisecondStr.padRight(3, '0'));

    return Duration(
        minutes: minute,
        seconds: second,
        milliseconds: millisecond
    ).inMilliseconds;
  }
}
class ParserVtt extends LyricsParse {
  // 匹配 VTT 时间轴行的正则
  // 格式示例: 00:00:01.500 --> 00:00:04.000
  // Group 1: 开始时间字符串
  // Group 2: 结束时间字符串
  // 注意：这里使用了非捕获组 (?:) 来处理可选的小时部分，保证核心匹配逻辑的健壮性
  static final RegExp _timeArrowRegex = RegExp(
      r"((?:\d{2}:)?\d{2}:\d{2}\.\d{3})\s+-->\s+((?:\d{2}:)?\d{2}:\d{2}\.\d{3})");

  ParserVtt(String lyric) : super(lyric);

  @override
  bool isOK() {
    return true;
  }

  @override
  List<LyricsLineModel> parseLines({bool isMain = true}) {
    var lines = const LineSplitter().convert(lyric);
    if (lines.isEmpty) return [];

    List<LyricsLineModel> lineList = [];

    // VTT 是块状结构，我们需要一个状态机或者循环跳跃的方式来解析
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // 1. 跳过 Header 和空行
      if (line.isEmpty || line == "WEBVTT") continue;

      // 2. 尝试匹配时间轴行 (包含 "-->")
      // 注意：VTT 可能在时间轴前有一行 ID，如果当前行不是时间轴，可能是 ID，我们直接忽略，继续找下一行即可
      var match = _timeArrowRegex.firstMatch(line);

      if (match != null) {
        // --- 找到时间轴，开始解析一个 Block ---

        // 3. 解析开始和结束时间
        int startTime = _parseVttTimestamp(match.group(1)!);
        int endTime = _parseVttTimestamp(match.group(2)!);

        // 4. 提取歌词文本
        // VTT 的文本位于时间轴的下一行，直到遇到空行或文件结束
        StringBuffer textBuffer = StringBuffer();

        // 向下预读寻找文本
        int j = i + 1;
        while (j < lines.length) {
          String textLine = lines[j].trim();
          // 如果遇到空行，说明这个 Block 结束了
          if (textLine.isEmpty) break;
          // 如果遇到下一个时间轴（容错处理，防止漏掉空行的情况），也结束
          if (textLine.contains("-->")) break;

          if (textBuffer.isNotEmpty) {
            textBuffer.write(" "); // 多行文本可以用空格或换行连接
          }
          textBuffer.write(textLine);
          j++;
        }

        // 更新外层循环索引，跳过已处理的文本行
        // j 指向的是空行或下一段的开始，下一次循环 i++ 会处理它，所以这里赋值 j - 1
        i = j - 1;

        String realLyrics = textBuffer.toString();
        // 处理特殊字符
        if (realLyrics == "//") realLyrics = "";

        // 5. 构建模型
        var lineModel = LyricsLineModel()
          ..startTime = startTime
          ..endTime = endTime; // VTT 包含结束时间，这对你的 getCurrentLine 逻辑非常有帮助

        if (isMain) {
          lineModel.mainText = realLyrics;
        } else {
          lineModel.extText = realLyrics;
        }

        lineList.add(lineModel);
      }
    }

    // 排序，防止错乱
    lineList.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    return lineList;
  }

  /// 解析 VTT 时间戳
  /// 支持格式：MM:SS.mmm 或 HH:MM:SS.mmm
  int _parseVttTimestamp(String timestamp) {
    List<String> parts = timestamp.split(":");

    int hours = 0;
    int minutes = 0;
    double seconds = 0;

    if (parts.length == 2) {
      // MM:SS.mmm
      minutes = int.parse(parts[0]);
      seconds = double.parse(parts[1]);
    } else if (parts.length == 3) {
      // HH:MM:SS.mmm
      hours = int.parse(parts[0]);
      minutes = int.parse(parts[1]);
      seconds = double.parse(parts[2]);
    } else {
      return 0;
    }

    // 将 double 类型的秒（包含毫秒）转换为总毫秒数
    // 例如 04.500 -> 4500ms
    int totalMilliseconds = (hours * 3600000) +
        (minutes * 60000) +
        ((seconds * 1000).round());

    return totalMilliseconds;
  }
}