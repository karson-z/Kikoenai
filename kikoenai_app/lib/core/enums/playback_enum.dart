enum ListenEventType {
  /// 开始播放
  start('start-listen'),

  /// 播放满5分钟
  fiveMinutes('listen-5mins');

  final String type;

  const ListenEventType(this.type);
}