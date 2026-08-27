import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../../../core/service/site/site_api_provider.dart';
import '../../../../core/service/site/site_api_setup.dart';
import '../provider/self_hosted_site_controller.dart';
import 'self_hosted_site_form_dialog.dart';

class SiteSelectionModal extends ConsumerStatefulWidget {
  const SiteSelectionModal({super.key});

  @override
  ConsumerState<SiteSelectionModal> createState() => _SiteSelectionModalState();
}

class _SiteSelectionModalState extends ConsumerState<SiteSelectionModal> {
  bool _isAdding = false;

  Future<void> _addSelfHostedSite() async {
    final server = await showSelfHostedSiteFormDialog(context);
    if (server == null || !mounted) return;
    setState(() => _isAdding = true);
    try {
      await ref.read(selfHostedSiteControllerProvider).addAndActivate(server);
      if (mounted) Navigator.pop(context, KikoeruSiteApi.info.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_describeError(error))));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(siteRegistryChangesProvider);
    final registry = ref.watch(siteRegistryProvider);
    final activeSiteId = ref.watch(activeSiteIdProvider);
    final theme = Theme.of(context);
    final contentSites = registry.allInfo
        .where((info) => isSelectableContentSiteId(info.id))
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text('选择内容站点', style: theme.textTheme.titleLarge),
          ),
          const Divider(height: 1),
          for (final info in contentSites)
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
          const Divider(height: 1),
          ListTile(
            key: const ValueKey('add_self_hosted_site'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: Icon(
              Icons.add_business_outlined,
              color: theme.colorScheme.primary,
            ),
            title: const Text('添加自建站'),
            subtitle: const Text('Kikoeru'),
            trailing: _isAdding
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isAdding ? null : _addSelfHostedSite,
          ),
        ],
      ),
    );
  }

  static String _describeError(Object error) {
    if (error is FormatException) return error.message;
    if (error is ArgumentError) return error.message?.toString() ?? '配置无效';
    if (error is StateError) return error.message;
    return '添加自建站失败';
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
