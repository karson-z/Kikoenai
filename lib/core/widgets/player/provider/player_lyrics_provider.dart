import 'dart:io';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/utils/network/api_client.dart';
import 'package:kikoenai/core/widgets/player/provider/player_controller_provider.dart';
import '../../../model/lyric_model.dart';
import '../../../service/file/archive_service.dart';
import '../../../service/lyrics/lyrics_parse_service.dart';
import '../../../storage/hive_storage.dart';
import '../../../utils/log/kikoenai_log.dart';
/// 字幕提供者
final lyricsProvider = FutureProvider<String?>((ref) async {
  final currentSub = ref.watch(playerControllerProvider.select((s) => s.currentSubtitle));
  final newUrl = currentSub?.mediaStreamUrl;

  if (newUrl == null || newUrl.isEmpty) return null;

  try {
    if (newUrl.startsWith('http')) {
      final api = ref.read(apiClientProvider);
      final response = await api.get(newUrl);
      return response.data.toString();
    } else {
      final file = File(newUrl);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return await ArchiveService.extractText(newUrl);
      }
    }
  } catch (e, stack) {
    KikoenaiLogger().e("加载字幕失败", error: e, stackTrace: stack);
    return null;
  }
});
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

  // 统一保存逻辑
  void _save(LyricConfigModel newConfig) {
    state = newConfig;
    setting.put(StorageKeys.lyricsStyleConfig, newConfig);
  }
}

// 2. 样式 Provider：只负责根据配置生成样式给 UI 使用
final lyricStyleProvider = Provider<LyricStyle>((ref) {
  final config = ref.watch(lyricConfigProvider);
  return LyricStyleFactory.createStyle(config);
});