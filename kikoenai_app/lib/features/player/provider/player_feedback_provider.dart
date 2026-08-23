import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/cache/cache_service.dart';
import 'package:kikoenai/features/player/provider/player_controller_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../../../core/service/site/site_api_provider.dart';

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

  void updatePlaybackStatus({
    required String siteId,
    required String workId,
    required bool isPlaying,
  }) {
    if (state.currentWorkId != workId || state.siteId != siteId) {
      _resetTracker(siteId, workId);
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

  void _resetTracker(String siteId, String newWorkId) {
    _timer?.cancel();
    state = PlaybackTrackerState(siteId: siteId, currentWorkId: newWorkId);
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

  Future<void> _checkAndReportStart() async {
    final isLocal = ref.read(playerControllerProvider).currentItem?.isLocal;
    if (!state.hasReportedStart &&
        state.currentWorkId != null &&
        state.siteId != null &&
        isLocal == false) {
      final siteId = state.siteId!;
      final recommendUuid = await CacheService.instance
          .getOrGenerateRecommendUuid(siteId: siteId);
      final authSession = CacheService.instance.getAuthSession(siteId: siteId);
      final currentUser = authSession?.user;
      if (currentUser == null) return;
      final api = ref.read(siteApiByIdProvider(siteId));
      if (!api.supports(SiteFeature.feedback)) return;
      // 埋点属尽力而为的遥测：失败仅打日志，不抛出未处理异常，
      // 也不在计时器里每秒重试（无论成败都只尝试一次）。
      try {
        await api.submitPlaybackFeedback(
          workId: state.currentWorkId!,
          recommendUuid: currentUser.recommenderUuid ?? recommendUuid,
          type: ListenEventType.start,
        );
        debugPrint("[埋点] 开始播放作品: ${state.currentWorkId}");
      } catch (e) {
        debugPrint("[埋点] 开始播放上报失败: $e");
      }
      state = state.copyWith(hasReportedStart: true);
    }
  }

  Future<void> _checkAndReport5Mins() async {
    final isLocal = ref.read(playerControllerProvider).currentItem?.isLocal;
    if (!state.hasReported5Mins &&
        state.currentWorkId != null &&
        state.siteId != null &&
        isLocal == false) {
      final siteId = state.siteId!;
      final authSession = CacheService.instance.getAuthSession(siteId: siteId);
      final currentUser = authSession?.user;
      if (currentUser == null) return;
      final recommendUuid = await CacheService.instance
          .getOrGenerateRecommendUuid(siteId: siteId);
      final api = ref.read(siteApiByIdProvider(siteId));
      if (!api.supports(SiteFeature.feedback)) return;
      // 同上：埋点失败只打日志，不抛异常、不每秒重试。
      try {
        await api.submitPlaybackFeedback(
          workId: state.currentWorkId!,
          recommendUuid: currentUser.recommenderUuid ?? recommendUuid,
          type: ListenEventType.fiveMinutes,
        );
        debugPrint("[埋点] 作品播放满5分钟: ${state.currentWorkId}");
      } catch (e) {
        debugPrint("[埋点] 5分钟上报失败: $e");
      }

      state = state.copyWith(hasReported5Mins: true);
    }
  }
}

final playbackTrackerProvider =
    NotifierProvider<PlaybackTrackerNotifier, PlaybackTrackerState>(
      () => PlaybackTrackerNotifier(),
    );
