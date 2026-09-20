import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

import 'package:kikoenai/core/utils/log/kikoenai_log.dart';

/// 媒体中心注册诊断。
///
/// audio_service 原生层（AudioService.java）只在收到携带
/// `playing: false → true` 边沿的 setState 时，才会执行
/// `startForeground` + `mediaSession.setActive(true)`，即“注册媒体中心”。
/// 这条链路有两处会把失败静默吞掉：
///
/// 1. 原生 `AudioHandlerInterface.onMethodCall` 整体 try/catch，
///    异常只 printStackTrace 后回传 Dart；
/// 2. Dart 侧 `_observePlaybackState` 把平台异常塞进
///    `AudioService.asyncError`，而应用从未监听它。
///
/// 本工具把第 2 处接上日志，并通过原生侧的通知快照反查注册结果
/// （媒体通知被投递 ⇔ startForeground 已执行 ⇔ 注册成功），
/// 让“是否注册成功”可以在日志页/logcat 直观看到。
///
/// 所有日志均带 forceLog，release 包无需连接调试器也能在应用内日志页看到。
class MediaCenterDiagnostics {
  MediaCenterDiagnostics._();

  static const _channel = MethodChannel('kikoenai/media_center_diagnostics');
  static const _tag = '【媒体中心】';
  static bool _attached = false;

  /// 挂接被静默吞掉的平台层错误流，并输出一次初始化基线。
  static void attach() {
    if (!Platform.isAndroid) return;
    if (_attached) return;
    _attached = true;

    AudioService.asyncError.listen((error) {
      KikoenaiLogger().e(
        '$_tag 平台层抛出异常（很可能就是注册失败的根因）',
        error: error,
        forceLog: true,
      );
    });

    _schedule(const Duration(milliseconds: 1200), '初始化基线');
  }

  /// playing 边沿发出后核验注册结果。
  ///
  /// 原生需要完成一次平台通道往返 + startForegroundService +
  /// startForeground，故取两个观察点覆盖慢设备。
  static void verifyAfterPlayEdge() {
    if (!Platform.isAndroid) return;
    _schedule(const Duration(milliseconds: 600), 'playing=true 边沿后');
    _schedule(const Duration(milliseconds: 2500), 'playing=true 边沿后复查');
  }

  /// 退后台后核验通知/会话是否仍存活。
  ///
  /// +30s 的探针用于捕捉 ROM 延迟冻结：若前两个探针有日志、第三个整体缺失，
  /// 说明进程在退后台几十秒内被冻结/查杀（Dart 定时器不再执行），
  /// 这正是 release 包媒体控制消失的典型形态。
  static void verifyAfterBackgrounded() {
    if (!Platform.isAndroid) return;
    _schedule(const Duration(milliseconds: 1000), '退后台后');
    _schedule(const Duration(milliseconds: 4000), '退后台后复查');
    _schedule(const Duration(seconds: 30), '退后台30秒');
  }

  static void _schedule(Duration delay, String trigger) {
    Timer(delay, () => _probeAndLog(trigger));
  }

  static Future<void> _probeAndLog(String trigger) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'probeMediaNotification',
      );
      final posted = raw?['notificationPosted'] == true;
      final musicActive = raw?['musicActive'] == true;
      final ongoing = raw?['ongoing'] == true;
      final postTime = raw?['postTime'];

      if (posted) {
        KikoenaiLogger().i(
          '$_tag [$trigger] 注册成功 ✅ 媒体通知存活 '
          '(ongoing=$ongoing, postTime=$postTime)，'
          '系统媒体控制中心此刻应显示本应用',
          forceLog: true,
        );
      } else if (musicActive) {
        KikoenaiLogger().e(
          '$_tag [$trigger] 注册失败 ❌ 音频正在输出，但媒体通知不存在——'
          'playing 边沿未到达原生层，或 startForeground 失败。'
          '请向上翻找「平台层抛出异常」日志定位原因',
          forceLog: true,
        );
      } else {
        KikoenaiLogger().w(
          '$_tag [$trigger] 未注册：当前无音频输出也无媒体通知。'
          '若此刻应处于播放状态，说明播放本身没有启动（检查播放错误日志）',
          forceLog: true,
        );
      }
    } on MissingPluginException {
      KikoenaiLogger().w(
        '$_tag [$trigger] 原生探针未实现，需要完整重新编译安装',
        forceLog: true,
      );
    } on PlatformException catch (e) {
      KikoenaiLogger().w(
        '$_tag [$trigger] 原生探针调用失败: ${e.message}',
        forceLog: true,
      );
    }
  }
}
