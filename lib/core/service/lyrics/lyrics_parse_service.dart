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
        fontSize: config.mainFontSize,
        color: Colors.white70,
        height: 1.2,
      ),

      activeStyle: TextStyle(
        fontSize: config.activeFontSize,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),

      translationStyle: TextStyle(
        fontSize: config.transFontSize,
        color: Colors.white70,
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
      fadeRange: FadeRange(top: 40, bottom: 80),

      // --- 动画时间 ---
      scrollDuration: const Duration(milliseconds: 240),
      scrollDurations: {
        500: const Duration(milliseconds: 500),
        1000: const Duration(milliseconds: 1000),
      },

      // --- 切换动画 ---
      enableSwitchAnimation: true,
      switchEnterDuration: const Duration(milliseconds: 500),
      switchExitDuration: const Duration(milliseconds: 500),
      switchEnterCurve: Curves.easeIn,
      switchExitCurve: Curves.easeOut,

      // --- 自动恢复逻辑 ---
      selectionAutoResumeMode: SelectionAutoResumeMode.neverResume,
      selectionAutoResumeDuration: const Duration(milliseconds: 320),
      activeAutoResumeDuration: const Duration(milliseconds: 2000),

      // --- 高亮渐变特效 ---
      activeHighlightGradient: const LinearGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFD7D7D7),
        ],
      ),
      activeHighlightExtraFadeWidth: 40,
    );
  }
}