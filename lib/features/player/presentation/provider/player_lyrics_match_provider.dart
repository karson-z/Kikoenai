import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/player/presentation/provider/player_controller_provider.dart';

import '../../../../core/service/audio/audio_extension.dart';
import '../../../../core/service/lyrics/match_lyrics_service.dart';
import '../../../../core/service/lyrics/search_lyrics_service.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../data/model/lyrics_match_state.dart';

final lyricsMatchControllerProvider = NotifierProvider<LyricsMatchController, LyricsMatchState>(() {
  return LyricsMatchController();
});

class LyricsMatchController extends Notifier<LyricsMatchState> {
  @override
  LyricsMatchState build() {
    _listenToPlayerTrackChanges();

    final initialTrack = ref.read(playerControllerProvider).currentTrack;
    final initialWorkId = initialTrack?.workData?.id;

    if (initialWorkId != null) {
      // 通过微任务触发异步请求，避免在 build 阶段直接修改 state 导致断言错误
      Future.microtask(() => _handleWorkChanged(initialWorkId));

      // 返回预设了 currentWorkId 的初始状态
      return LyricsMatchState(
        currentWorkId: initialWorkId,
        isSearching: true,
      );
    }

    return const LyricsMatchState();
  }

  void _listenToPlayerTrackChanges() {
    // 监听播放器的当前曲目变化
    ref.listen(playerControllerProvider.select((p) => p.currentTrack), (previousTrack, currentTrack) {
      if (currentTrack == null) {
        state = const LyricsMatchState();
        return;
      }
      final newWorkId = currentTrack.workData?.id;
      final oldWorkId = state.currentWorkId;
      if (newWorkId != null && newWorkId != oldWorkId) {
        _handleWorkChanged(newWorkId);
      }
    });
  }

  Future<void> _handleWorkChanged(int workId) async {
    state = state.copyWith(currentWorkId: workId, isSearching: true);

    try {
      final targetSubtitleList = await SearchLyricsService.findLyrics(workId, ref);

      // 检查在异步请求期间，播放器是否已经切走了，防止旧请求覆盖新状态 (竞态条件处理)
      final activeTrack = ref.read(playerControllerProvider).currentTrack;
      if (activeTrack?.workData?.id != workId) return;

      final currentWorkPlaylist = ref.read(playerControllerProvider)
          .playlist
          .where((item) => item.workData?.id == workId)
          .toList();

      final playListProcessed = LyricsDataProcess.batchPlayListProcess(currentWorkPlaylist);
      final lyricListProcessed = LyricsDataProcess.batchLyricsProcess(targetSubtitleList);

      // 执行自动匹配
      final matches = MatchLyrics.match(playListProcessed, lyricListProcessed);

      state = state.copyWith(
        isSearching: false,
        lyricsList: targetSubtitleList,
        subtitleMapping: matches,
      );

      // 自动匹配失败时的处理逻辑（如弹窗提示）交由 UI 层的 listener 处理，保持 Controller 纯粹
    } catch (e) {
      state = state.copyWith(isSearching: false);
    }
  }

  /// 供 UI 层（手动匹配面板）调用，更新并持久化匹配结果
  void updateMapping(Map<String, FileNode?> draftMapping) {
    // 这个 Map 用于持久化存储（不包含 null）
    final validMapping = <String, FileNode>{};
    // 这个 Map 用于更新内存状态
    final updatedStateMapping = Map<String, FileNode?>.from(state.subtitleMapping);

    draftMapping.forEach((trackId, fileNode) {
      if (fileNode != null) {
        // 如果有真实的字幕节点，加入有效映射
        validMapping[trackId] = fileNode;
        updatedStateMapping[trackId] = fileNode;
      } else {
        // 如果是 null，说明用户点击了“取消关联”
        // 1. 从本地存储中彻底删除这条记录
        AppStorage.lyricMatchBox.delete(trackId);
        // 2. 从内存状态中移除
        updatedStateMapping.remove(trackId);
      }
    });

    // 仅将有效的、非空的关联写入持久化存储（你的 persistMatchResults 需要非空 Map）
    if (validMapping.isNotEmpty) {
      MatchLyrics.persistMatchResults(validMapping);
    }

    // 更新 Riverpod 状态
    state = state.copyWith(subtitleMapping: updatedStateMapping);
  }
}