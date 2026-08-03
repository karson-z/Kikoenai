/// 播放反馈埋点事件类型。
///
/// 用于 [SiteApi.submitPlaybackFeedback] 上报用户收听行为。
enum ListenEventType {
  /// 开始播放
  start('start-listen'),

  /// 播放满 5 分钟
  fiveMinutes('listen-5mins');

  /// 服务端期望的事件标识字符串
  final String type;

  const ListenEventType(this.type);
}
