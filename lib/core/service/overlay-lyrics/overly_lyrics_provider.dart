import 'package:flutter_lyric/core/lyric_model.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/overly-lyrics/presentation/provider/overly_lyrics_provider.dart';
import '../../../features/player/presentation/provider/player_controller_provider.dart';
import '../../../features/player/presentation/provider/player_lyrics_provider.dart';

// 1. 定义解析缓存 Provider
// 作用：只在原始歌词字符串发生变化时执行一次解析，生成 List<LyricLine> 供高频进度查询
final parsedLyricsProvider = Provider<List<LyricLine>?>((ref) {
  final lyricsAsync = ref.watch(lyricsProvider);
  final rawLyric = lyricsAsync.value;

  if (rawLyric == null || rawLyric.isEmpty) {
    return null;
  }

  try {
    // 调用自定义的静态解析方法
    // 若业务场景中包含单独的翻译歌词源，可通过 translationLyric 参数传入
    final lyricModel = LyricParse.parse(rawLyric);
    return lyricModel.lines;
  } catch (e) {
    return null;
  }
});

// 2. 完善的同步下发服务
final subtitleSyncProvider = Provider<void>((ref) {
  ref.listen<Duration>(
    playerControllerProvider.select((s) => s.progressBarState.current),
        (previousProgress, currentProgress) {
      final isShowing = ref.read(lyricsOverlayProvider).isShowing;
      if (!isShowing) return;

      final lyricLines = ref.read(parsedLyricsProvider);
      if (lyricLines == null || lyricLines.isEmpty) {
        print("====== 同步服务异常: 解析的歌词数据为空 ======");
        return;
      }

      final String currentText = _findCurrentLine(lyricLines, currentProgress);
      final lastSentText = ref.read(lyricsOverlayProvider).text;

      if (currentText.isNotEmpty && currentText != lastSentText) {
        print("====== 主应用准备下发歌词: $currentText ======");
        ref.read(lyricsOverlayProvider.notifier).updateText(currentText);
      }
    },
  );
});

// 匹配当前进度对应的歌词文本
String _findCurrentLine(List<LyricLine> lines, Duration progress) {
  for (int i = lines.length - 1; i >= 0; i--) {
    final line = lines[i];

    // LyricLine 中的 start 为 Duration 类型，直接比对
    if (progress >= line.start) {
      final mainText = line.text ?? "";
      final translation = line.translation;

      // 如果存在翻译歌词，拼接为双行展示
      if (translation != null && translation.isNotEmpty) {
        return "$mainText\n$translation";
      }
      return mainText;
    }
  }
  return "";
}