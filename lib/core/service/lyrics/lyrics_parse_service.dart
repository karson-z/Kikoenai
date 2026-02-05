import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lyric/core/lyric_model.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_lyric/core/lyric_style.dart';

import '../../model/lyric_model.dart';
/// Vtt 字幕解析器
class VttParser extends LyricParse {
  // 匹配 VTT 时间轴的正则：支持 00:00.000 或 00:00:00.000
  static final RegExp _timeArrowRegex = RegExp(r'(\d{2,}:?\d{2}:\d{2}\.\d{3})|(\d{2}:\d{2}\.\d{3})');
  @override
  bool isMatch(String mainLyric) {
    return mainLyric.contains("WEBVTT");
  }
  @override
  LyricModel parseRaw(String mainLyric, {String? translationLyric}) {
    final lines = const LineSplitter().convert(mainLyric);
    final List<LyricLine> lyricLines = [];
    final Map<String, String> tags = {};

    // 提取翻译映射 (ms -> text)
    final translationMap = LrcParser.extractTranslationMap(translationLyric);

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      if (line.isEmpty || line == "WEBVTT") continue;

      // 提取 VTT 标签（如 [Kind: captions]）
      if (line.startsWith('[') && line.contains(':')) {
        final tagMatch = RegExp(r'\[(\w+):(.*?)\]').firstMatch(line);
        if (tagMatch != null) {
          tags[tagMatch.group(1)!] = tagMatch.group(2)!;
        }
        continue;
      }

      // 寻找时间轴行
      final matches = _timeArrowRegex.allMatches(line).toList();
      if (matches.length >= 2) {
        // 匹配到开始和结束时间
        int startMs = _parseVttTimestamp(matches[0].group(0)!);
        int endMs = _parseVttTimestamp(matches[1].group(0)!);

        // 提取文本内容
        StringBuffer textBuffer = StringBuffer();
        int j = i + 1;
        while (j < lines.length) {
          String textLine = lines[j].trim();
          if (textLine.isEmpty || _timeArrowRegex.hasMatch(textLine)) break;

          if (textBuffer.isNotEmpty) textBuffer.write(" ");
          textBuffer.write(textLine);
          j++;
        }
        i = j - 1;

        String content = textBuffer.toString();
        // 过滤常见的 VTT 样式标签 如 <c.yellow>...</c>
        content = content.replaceAll(RegExp(r'<[^>]*>'), '');

        if (content.isNotEmpty && content != "//") {
          lyricLines.add(LyricLine(
            start: Duration(milliseconds: startMs),
            end: Duration(milliseconds: endMs),
            text: content,
            translation: translationMap[startMs], // 尝试匹配翻译
          ));
        }
      }
    }

    lyricLines.sort((a, b) => a.start.compareTo(b.start));
    return LyricModel(lines: lyricLines, tags: tags);
  }

  /// 解析 VTT 时间戳为毫秒
  int _parseVttTimestamp(String timestamp) {
    try {
      List<String> parts = timestamp.split(":");
      int hours = 0;
      int minutes = 0;
      double secondsWithMs = 0;

      if (parts.length == 3) {
        // HH:MM:SS.mmm
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        secondsWithMs = double.parse(parts[2]);
      } else if (parts.length == 2) {
        // MM:SS.mmm
        minutes = int.parse(parts[0]);
        secondsWithMs = double.parse(parts[1]);
      }

      return (hours * 3600000 + minutes * 60000 + (secondsWithMs * 1000).round());
    } catch (e) {
      return 0;
    }
  }
}

class LyricStyleFactory {
  static LyricStyle createStyle(LyricConfigModel config) {
    return LyricStyle(
      textStyle: TextStyle(
        fontSize: config.mainFontSize, // 建议设置小一点，如 18-20
        color: Colors.white.withOpacity(0.5), // 降低不透明度，模拟“失焦”感
        height: 1.5, // 增加行高，增加呼吸感
        fontWeight: FontWeight.w500,
      ),

      activeStyle: TextStyle(
        fontSize: config.activeFontSize, // 建议设置大一点，如 28-32，形成巨大反差
        color: Colors.white,
        fontWeight: FontWeight.w800, // 极粗字体，强调视觉重心
        height: 1.2,
      ),

      translationStyle: TextStyle(
        fontSize: config.transFontSize,
        color: Colors.white.withOpacity(0.4), // 翻译更淡
        height: 1.5,
      ),

      lineGap: config.lineGap,
      translationLineGap: config.translationGap,
      // --- 颜色 ---
      translationActiveColor: Colors.white,
      selectedColor: Colors.white,
      selectedTranslationColor: Colors.white,
      // --- 对齐与布局 ---
      lineTextAlign: TextAlign.left,
      contentAlignment: CrossAxisAlignment.start,
      // 具体的 Padding
      contentPadding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
      // --- 锚点 ---
      selectionAnchorPosition: 0.5,
      activeAnchorPosition: 100,
      selectionAlignment: MainAxisAlignment.end,
      activeAlignment: MainAxisAlignment.start,

      // --- 渐隐效果 ---
      fadeRange: FadeRange(top: 0.1, bottom: 0.3),

      // 滚动动画：要有“惯性”感
      scrollDuration: const Duration(milliseconds: 650), // 稍慢一点，显得优雅
      scrollCurve: Curves.easeInOutCubic, // 使用三次贝塞尔曲线，起步慢->加速->减速停止

      // 切换动画（行变大变亮的过程）：要有“弹跳”感
      enableSwitchAnimation: true,
      switchEnterDuration: const Duration(milliseconds: 400),
      switchExitDuration: const Duration(milliseconds: 400),

      // 核心技巧：使用 easeOutBack 或 easeOutQuart
      // easeOutBack 会让文字变大时稍微“冲”过头一点点再缩回来，产生弹性（慎用，可能太夸张）
      // easeOutQuart 则是非常平滑且快速的放大，非常接近 iOS 系统动画
      switchEnterCurve: Curves.easeOutQuart,
      switchExitCurve: Curves.easeInQuad,

      // --- 自动恢复逻辑 ---
      selectionAutoResumeMode: SelectionAutoResumeMode.neverResume,
      selectionAutoResumeDuration: const Duration(milliseconds: 320),
      activeAutoResumeDuration: const Duration(milliseconds: 2000),

      // --- 高亮渐变特效 ---
      activeHighlightGradient: LinearGradient(
        begin: Alignment.topCenter, // 从上到下
        end: Alignment.bottomCenter,
        colors: [
          // 起始：稍微带点亮度的半透明白 (根据需要调整透明度 0.1 - 0.3)
          Colors.white.withOpacity(0.25),
          // 结束：几乎完全透明，但这能让渐变更柔和
          Colors.white.withOpacity(0.05),
        ],
        // 关键：加一个中间点，让白色主要集中在中间，两边快速淡出
        stops: const [0.0, 1.0],
      ),
      activeHighlightExtraFadeWidth: 40,
    );
  }
}