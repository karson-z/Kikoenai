import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playback_track_state.dart';

class PlaybackTrackerNotifier extends Notifier<PlaybackTrackerState> {
  Timer? _timer;

  @override
  PlaybackTrackerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    // 返回初始状态
    return const PlaybackTrackerState();
  }
  void updatePlaybackStatus({required String workId, required bool isPlaying}) {
    if (state.currentWorkId != workId) {
      _resetTracker(workId);
    }
    state = state.copyWith(isPlaying: isPlaying);

    // 3. 计时器控制
    if (isPlaying) {
      _startTimer();
      _checkAndReportStart();
    } else {
      _stopTimer();
    }
  }

  void _resetTracker(String newWorkId) {
    _timer?.cancel();
    state = PlaybackTrackerState(currentWorkId: newWorkId);
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newSeconds = state.accumulatedSeconds + 1;

      state = state.copyWith(accumulatedSeconds: newSeconds);

      // 300秒 = 5分钟
      if (newSeconds >= 300) {
        _checkAndReport5Mins();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkAndReportStart() {
    if (!state.hasReportedStart && state.currentWorkId != null) {
      // TODO: 在这里调用你的埋点/上报接口
      print("📊 [埋点] 开始播放作品: ${state.currentWorkId}");

      state = state.copyWith(hasReportedStart: true);
    }
  }

  void _checkAndReport5Mins() {
    if (!state.hasReported5Mins && state.currentWorkId != null) {
      // TODO: 在这里调用你的埋点/上报接口
      print("📊 [埋点] 作品播放满5分钟: ${state.currentWorkId}");

      state = state.copyWith(hasReported5Mins: true);
    }
  }
}

final playbackTrackerProvider =
NotifierProvider<PlaybackTrackerNotifier, PlaybackTrackerState>(() => PlaybackTrackerNotifier());


