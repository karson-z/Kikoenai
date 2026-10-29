import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import '../proxy/auto_proxy_service.dart';

/// 全局媒体播放管理器
///
/// 负责持有底层的 [Player] 与 [VideoController] 实例。
/// UI 层可通过此类挂载视频画面，音频服务层通过此类控制播放核心。
class PlayerService {
  PlayerService._() {
    final native = player.platform;
    if (native is NativePlayer) {
      // media_kit runs this hook before opening the network stream. Keeping it
      // here also covers opens triggered by repeat/playlist and header refresh.
      native.onLoadHooks.add(() async {
        final path = await native.getProperty(
          'path',
          waitForInitialization: false,
        );
        final uri = Uri.tryParse(path);
        final endpoint = uri == null
            ? null
            : ProxyService.current.proxyFor(uri);
        final proxy = endpoint?.url ?? '';
        await native.setProperty(
          'http-proxy',
          proxy,
          waitForInitialization: false,
        );
        // setProperty ignores mpv's return code; read back to detect rejection.
        if (await native.getProperty(
              'http-proxy',
              waitForInitialization: false,
            ) !=
            proxy) {
          KikoenaiLogger(tag: 'PlayerService').e('[Proxy] mpv 未接受 HTTP 代理设置');
        }
      });
    }
  }

  static final PlayerService _instance = PlayerService._();

  static PlayerService get instance => _instance;

  /// 全局唯一的媒体播放器实例（在主 isolate 创建）。
  ///
  /// `logLevel: MPVLogLevel.error`：生产环境只输出 mpv 错误级日志，
  /// 显著降低 FFI 回调频率——高频回调在热重载换码瞬间更容易把 isolate
  /// 卡在安全点外导致"暂停后退出"。排查 mpv 问题时临时改回
  /// `MPVLogLevel.debug` 即可（日志页会显示 `[mpv]` 条目）。
  final Player player = Player(
    configuration: const PlayerConfiguration(
      logLevel: MPVLogLevel.error,
      bufferSize: 32 * 1024 * 1024,
    ),
  );

  VideoController? _videoController;

  VideoController get videoController {
    _videoController ??= VideoController(
      player,
      configuration: _initVideoControllerConfig(),
    );
    return _videoController!;
  }

  /// 初始化视频播放控制器配置
  VideoControllerConfiguration _initVideoControllerConfig() {
    // TODO 初始化逻辑
    return const VideoControllerConfiguration();
  }

  /// 控制硬件视频解码器的开启与关闭，以优化功耗
  Future<void> toggleVideoDecoding(bool enable) async {
    try {
      if (enable) {
        await player.setVideoTrack(VideoTrack.auto());
        KikoenaiLogger(tag: 'PlayerService').d("视频画面解码已开启");
      } else {
        await player.setVideoTrack(VideoTrack.no());
        KikoenaiLogger(tag: 'PlayerService').d("视频画面解码已关闭，进入纯音频模式");
      }
    } catch (e) {
      KikoenaiLogger(tag: 'PlayerService').e("切换视频轨道失败: $e");
    }
  }

  /// 清理底层播放核心资源
  Future<void> dispose() async {
    await player.dispose();
    _videoController = null;
  }
}
