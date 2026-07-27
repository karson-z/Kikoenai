/// 服务器健康状态。
enum HealthStatus {
  /// 健康，可正常访问
  healthy,

  /// 不健康，无法访问或响应异常
  unhealthy,

  /// 未知（尚未检测）
  unknown,
}

/// 服务器健康检查结果。
class ServerHealth {
  /// 被检测的服务器 ID
  final String serverId;

  /// 健康状态
  final HealthStatus status;

  /// 响应延迟（毫秒）。仅 [status] 为 [HealthStatus.healthy] 时有意义。
  final int? latencyMs;

  /// 失败原因（仅 [status] 为 [HealthStatus.unhealthy] 时有值）
  final String? errorMessage;

  /// 检测时间
  final DateTime checkedAt;

  const ServerHealth({
    required this.serverId,
    required this.status,
    this.latencyMs,
    this.errorMessage,
    required this.checkedAt,
  });

  /// 便捷判断
  bool get isHealthy => status == HealthStatus.healthy;

  @override
  String toString() {
    final parts = <String>['serverId: $serverId', 'status: $status'];
    if (latencyMs != null) parts.add('latency: ${latencyMs}ms');
    if (errorMessage != null) parts.add('error: $errorMessage');
    return 'ServerHealth(${parts.join(', ')})';
  }
}
