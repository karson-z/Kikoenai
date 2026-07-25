import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/utils/data/charset_cover.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';
import 'package:kikoenai/features/player/presentation/provider/player_lyrics_match_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../core/service/file/archive_service.dart';
import '../../../../core/service/lyrics/lyrics_parse_service.dart';
import '../../../../core/storage/hive_storage.dart';

/// 字幕提供者
final lyricsProvider = FutureProvider<String?>((ref) async {
  final currentItemId = ref.watch(
    playerControllerProvider.select((s) => s.currentItem?.id),
  );
  if (currentItemId == null) return null;
  final subtitleMapping = ref.watch(
    lyricsMatchControllerProvider.select((s) => s.subtitleMapping),
  );
  final currentSub = subtitleMapping[currentItemId];
  final newUrl = currentSub?.mediaStreamUrl;
  if (newUrl == null || newUrl.isEmpty) return null;
  final api = ref.read(apiClientProvider);
  return fetchLyricContent(newUrl, api);
});
Future<String?> fetchLyricContent(String? url, dynamic apiClient) async {
  if (url == null || url.isEmpty) return null;

  try {
    if (url.startsWith('http')) {
      // 网络歌词必须保留原始字节，避免 Dio 预解码导致乱码。
      final response = await apiClient.getBytes(
        url,
        options: Options(
          headers: const {'Accept': 'text/plain, text/lrc, */*'},
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      final contentType = response.headers.value(Headers.contentTypeHeader);
      final hintedCharset = FileEncodingHelper.extractCharsetFromContentType(
        contentType,
      );
      final decoded = await FileEncodingHelper.decodeBytes(
        bytes,
        hintedCharset: hintedCharset,
      );
      return decoded.content;
    } else {
      // 本地文件读取或解压
      final file = File(url);
      if (await file.exists()) {
        final result = await FileEncodingHelper.readFile(file);
        return result.content;
      } else {
        return await ArchiveService.extractText(url);
      }
    }
  } catch (e, stack) {
    KikoenaiLogger().e("加载字幕失败, URL: $url", error: e, stackTrace: stack);
    rethrow;
  }
}

/// 自定义的加载方法，支持传入解析器列表
extension LyricControllerExt on LyricController {
  void loadLyricWithParsers(
    String lyric, {
    String? translationLyric,
    List<LyricParse>? parsers,
  }) {
    final lyricModel = LyricParse.parse(
      lyric,
      translationLyric: translationLyric,
      parsers: parsers,
    );
    loadLyricModel(lyricModel);
  }
}

/// 字幕样式提供者
final lyricConfigProvider =
    NotifierProvider<LyricConfigNotifier, LyricConfigModel>(() {
      return LyricConfigNotifier();
    });

class LyricConfigNotifier extends Notifier<LyricConfigModel> {
  Box get setting => AppStorage.settingsBox;

  @override
  LyricConfigModel build() {
    return setting.get(
      StorageKeys.lyricsStyleConfig,
      defaultValue: const LyricConfigModel(),
    );
  }

  void updateMainFontSize(double val) =>
      _save(state.copyWith(mainFontSize: val));

  void updateTransFontSize(double val) =>
      _save(state.copyWith(transFontSize: val));

  void updateActiveFontSize(double val) =>
      _save(state.copyWith(activeFontSize: val));

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
