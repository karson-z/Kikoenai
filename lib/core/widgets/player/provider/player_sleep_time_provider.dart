import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 定义倒计时状态提供者
final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, Duration?>(() {
  return SleepTimerNotifier();
});

class SleepTimerNotifier extends Notifier<Duration?> {
  Timer? _timer;

  @override
  Duration? build() {
    // 默认没有开启定时，状态为 null
    return null;
  }

  /// 开始倒计时
  void startTimer(Duration duration) {
    _timer?.cancel();
    state = duration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null || state!.inSeconds <= 0) {
        stopTimer();
      } else {
        state = state! - const Duration(seconds: 1);
      }
    });
  }

  /// 停止/取消倒计时
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}