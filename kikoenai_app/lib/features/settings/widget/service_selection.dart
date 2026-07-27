import 'package:flutter/material.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';
import '../../../../core/service/site/site_api_setup.dart';

class ServerSelectionModal extends StatefulWidget {
  const ServerSelectionModal({super.key});
  @override
  State<ServerSelectionModal> createState() => _ServerSelectionModalState();
}

class _ServerSelectionModalState extends State<ServerSelectionModal> {
  // 存储每个服务器 ID 对应的延迟 (毫秒)，-1 表示失败，null 表示正在测速

  final Map<String, int?> _latencies = {};

  @override
  void initState() {
    super.initState();
    // 弹窗打开时，立即开始所有节点的测速
    _pingAll();
  }

  /// 并发测试所有节点
  void _pingAll() {
    for (final server in AsmrOneSiteApi.info.servers) {
      _checkLatency(server);
    }
  }

  /// 单个节点测速逻辑
  Future<void> _checkLatency(ServerInfo server) async {
    // 标记为正在加载
    if (mounted) setState(() => _latencies[server.id] = null);

    try {
      final health = await siteApi.checkHealth(server);
      if (mounted) {
        setState(() {
          _latencies[server.id] = health.isHealthy ? health.latencyMs : -1;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _latencies[server.id] = -1; // -1 代表超时或错误
        });
      }
    }
  }

  /// 根据延迟获取颜色
  Color _getLatencyColor(int ms) {
    if (ms < 0) return Colors.red; // 错误
    if (ms < 200) return Colors.green; // 极快
    if (ms < 500) return Colors.orange; // 一般
    return Colors.redAccent; // 慢
  }

  @override
  Widget build(BuildContext context) {
    final currentServer = siteApi.currentServer.id;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '切换服务器',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                // 刷新按钮
                IconButton(
                  onPressed: _pingAll,
                  icon: const Icon(Icons.refresh),
                  tooltip: '重新测速',
                )
              ],
            ),
          ),
          const Divider(),

          // 列表区域
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AsmrOneSiteApi.info.servers.length,
              itemBuilder: (context, index) {
                final server = AsmrOneSiteApi.info.servers[index];
                final latency = _latencies[server.id];
                final isSelected = currentServer == server.id;

                return InkWell(
                  onTap: () {
                    // 选中并关闭弹窗
                    switchServer(server.id);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                    child: Row(
                      children: [
                        // 1. 选中指示器
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? theme.colorScheme.primary : theme.disabledColor,
                          size: 20,
                        ),
                        const SizedBox(width: 16),

                        // 2. 服务器名称
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                server.baseUrl,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // 3. 延迟显示 (核心功能)
                        SizedBox(
                          width: 60,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildLatencyWidget(latency, theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom), // 避让底部小白条
        ],
      ),
    );
  }

  Widget _buildLatencyWidget(int? latency, ThemeData theme) {
    // 情况1: 正在加载
    if (latency == null) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // 情况2: 失败
    if (latency == -1) {
      return const Text(
        '超时',
        style: TextStyle(color: Colors.red, fontSize: 12),
      );
    }

    // 情况3: 成功显示毫秒
    return Text(
      '${latency}ms',
      style: TextStyle(
        color: _getLatencyColor(latency),
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}
