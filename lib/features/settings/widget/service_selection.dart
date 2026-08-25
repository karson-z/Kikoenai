import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../../../core/service/site/site_api_provider.dart';
import '../../../../core/service/site/site_api_setup.dart';

class SiteSelectionModal extends ConsumerWidget {
  const SiteSelectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(siteRegistryChangesProvider);
    final registry = ref.watch(siteRegistryProvider);
    final activeSiteId = ref.watch(activeSiteIdProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text('选择站点', style: theme.textTheme.titleLarge),
          ),
          const Divider(height: 1),
          for (final info in registry.allInfo)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: Icon(
                info.id == activeSiteId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: info.id == activeSiteId
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(info.name),
              subtitle: Text(info.id),
              trailing: Text('v${info.version}'),
              onTap: info.id == activeSiteId
                  ? null
                  : () async {
                      await ref
                          .read(activeSiteIdProvider.notifier)
                          .activate(info.id);
                      if (context.mounted) Navigator.pop(context, info.id);
                    },
            ),
        ],
      ),
    );
  }
}

class ServerSelectionModal extends ConsumerStatefulWidget {
  const ServerSelectionModal({super.key, this.siteId});

  final String? siteId;

  @override
  ConsumerState<ServerSelectionModal> createState() =>
      _ServerSelectionModalState();
}

class _ServerSelectionModalState extends ConsumerState<ServerSelectionModal> {
  final Map<String, int?> _latencies = {};

  @override
  void initState() {
    super.initState();
    _pingAll();
  }

  void _pingAll() {
    final runtime = _readRuntime();
    for (final server in runtime.info.servers) {
      _checkLatency(runtime.api, server);
    }
  }

  SiteRuntime _readRuntime() {
    final siteId = widget.siteId;
    return siteId == null
        ? ref.read(activeSiteProvider)
        : ref.read(siteRuntimeByIdProvider(siteId));
  }

  Future<void> _checkLatency(SiteApi api, ServerInfo server) async {
    if (mounted) setState(() => _latencies[server.id] = null);
    try {
      final health = await api.checkHealth(server);
      if (mounted) {
        setState(() {
          _latencies[server.id] = health.isHealthy ? health.latencyMs : -1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _latencies[server.id] = -1);
    }
  }

  Color _latencyColor(int milliseconds) {
    if (milliseconds < 0) return Colors.red;
    if (milliseconds < 200) return Colors.green;
    if (milliseconds < 500) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final siteId = widget.siteId;
    final runtime = siteId == null
        ? ref.watch(activeSiteProvider)
        : ref.watch(siteRuntimeByIdProvider(siteId));
    final servers = runtime.info.servers;
    final currentServerId = runtime.api.currentServer.id;
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('选择服务器', style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: _pingAll,
                  icon: const Icon(Icons.refresh),
                  tooltip: '重新测速',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final server in servers)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: Icon(
                currentServerId == server.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentServerId == server.id
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(server.label),
              subtitle: Text(server.region ?? server.resolvedBaseUrl),
              trailing: _latencyLabel(server.id),
              onTap: currentServerId == server.id
                  ? null
                  : () async {
                      await switchServer(server.id, siteId: runtime.siteId);
                      ref.invalidate(siteRuntimeByIdProvider(runtime.siteId));
                      if (context.mounted) Navigator.pop(context, server.id);
                    },
            ),
        ],
      ),
    );
  }

  Widget _latencyLabel(String serverId) {
    if (!_latencies.containsKey(serverId)) return const SizedBox.shrink();
    final latency = _latencies[serverId];
    if (latency == null) {
      return const SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(
      latency < 0 ? '不可用' : '$latency ms',
      style: TextStyle(color: _latencyColor(latency)),
    );
  }
}
