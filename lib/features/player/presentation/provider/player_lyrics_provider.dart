import 'dart:io';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/presentation/provider/player_lyrics_match_provider.dart';
import '../../../../core/model/lyric_model.dart';
import '../../../../core/service/file/archive_service.dart';
import '../../../../core/service/lyrics/lyrics_parse_service.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/utils/log/kikoenai_log.dart';
/// 字幕提供者
final lyricsProvider = FutureProvider<String?>((ref) async {
  final currentTrackId = ref.watch(playerControllerProvider.select((s) => s.currentTrack?.id));
  if (currentTrackId == null) return null;
  final subtitleMapping = ref.watch(lyricsMatchControllerProvider.select((s) => s.subtitleMapping));
  final currentSub = subtitleMapping[currentTrackId];
  final newUrl = currentSub?.mediaStreamUrl;
  if (newUrl == null || newUrl.isEmpty) return null;
  final api = ref.read(apiClientProvider);
  return fetchLyricContent(newUrl, api);
});

// fetchLyricContent 方法保持你原来的不变即可
Future<String?> fetchLyricContent(String? url, dynamic apiClient) async {
  if (url == null || url.isEmpty) return null;

  try {
    if (url.startsWith('http')) {
      // 网络请求获取
      final response = await apiClient.get(url);
      return response.data.toString();
    } else {
      // 本地文件读取或解压
      final file = File(url);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return await ArchiveService.extractText(url);
      }
    }
  } catch (e, stack) {
    KikoenaiLogger().e("加载字幕失败, URL: $url", error: e, stackTrace: stack);
    return null;
  }
}
/// 自定义的加载方法，支持传入解析器列表
extension LyricControllerExt on LyricController {
  void loadLyricWithParsers(String lyric, {
    String? translationLyric,
    List<LyricParse>? parsers
  }) {
    final lyricModel = LyricParse.parse(
      lyric,
      translationLyric: translationLyric,
      parsers: parsers,
    );
    // 调用原有的 loadLyricModel 处理逻辑
    loadLyricModel(lyricModel);
  }
}
/// 字幕样式提供者
final lyricConfigProvider = NotifierProvider<LyricConfigNotifier, LyricConfigModel>(() {
  return LyricConfigNotifier();
});

class LyricConfigNotifier extends Notifier<LyricConfigModel> {
  Box get setting => AppStorage.settingsBox;

  @override
  LyricConfigModel build() {
    return setting.get(StorageKeys.lyricsStyleConfig,defaultValue: const LyricConfigModel());
  }

  void updateMainFontSize(double val) => _save(state.copyWith(mainFontSize: val));

  void updateTransFontSize(double val) => _save(state.copyWith(transFontSize: val));

  void updateActiveFontSize(double val) => _save(state.copyWith(activeFontSize: val));

  void updateLineGap(double val) => _save(state.copyWith(lineGap: val));

  void updateTransGap(double val) => _save(state.copyWith(translationGap: val));

  void resetToDefault() {
    _save(const LyricConfigModel());
  }
  // 统一保存逻辑
  void _save(LyricConfigModel newConfig) {
    state = newConfig;
    setting.put(StorageKeys.lyricsStyleConfig, newConfig);
  }
}
final lyricStyleProvider = Provider<LyricStyle>((ref) {
  final config = ref.watch(lyricConfigProvider);
  return LyricStyleFactory.createStyle(config);
});