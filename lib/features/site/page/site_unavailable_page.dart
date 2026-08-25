import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/service/site/site_api_provider.dart';
import '../../../core/service/site/site_api_setup.dart';
import '../../../core/service/site/site_unavailable_controller.dart';
import '../../settings/widget/service_selection.dart';

class SiteUnavailablePage extends ConsumerStatefulWidget {
  const SiteUnavailablePage({super.key});

  @override
  ConsumerState<SiteUnavailablePage> createState() =>
      _SiteUnavailablePageState();
}

class _SiteUnavailablePageState extends ConsumerState<SiteUnavailablePage> {
  bool _isRetrying = false;
  String? _retryMessage;

  Future<void> _retry(SiteUnavailableIncident incident) async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _retryMessage = null;
    });

    final selected = await recheckSiteServers(incident.siteId);
    if (!mounted) return;
    if (selected == null) {
      setState(() {
        _isRetrying = false;
        _retryMessage = '仍未发现可用服务器，请稍后再试';
      });
      return;
    }

    _leaveErrorPage(incident);
  }

  Future<void> _selectServer(SiteUnavailableIncident incident) async {
    final selectedServerId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ServerSelectionModal(siteId: incident.siteId),
    );
    if (!mounted || selectedServerId == null) return;
    _leaveErrorPage(incident);
  }

  Future<void> _selectSite(SiteUnavailableIncident incident) async {
    final activeSiteId = ref.read(activeSiteIdProvider);
    if (activeSiteId != incident.siteId) {
      _leaveErrorPage(null, destination: AppRoutes.home);
      return;
    }

    final selectedSiteId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const SiteSelectionModal(),
    );
    if (!mounted || selectedSiteId == null) return;
    _leaveErrorPage(null, destination: AppRoutes.home);
  }

  void _leaveErrorPage(
    SiteUnavailableIncident? incident, {
    String? destination,
  }) {
    final controller = ref.read(siteUnavailableControllerProvider);
    final target = destination ?? incident?.returnLocation ?? AppRoutes.home;
    final extra = destination == null ? incident?.returnExtra : null;
    controller.clear();
    if (mounted) context.go(target, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(siteRegistryChangesProvider);
    final controller = ref.watch(siteUnavailableControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final incident = controller.incident;
        if (incident == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildPage(context, incident);
      },
    );
  }

  Widget _buildPage(BuildContext context, SiteUnavailableIncident incident) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final registry = ref.watch(siteRegistryProvider);
    final runtime = registry.runtimeOf(incident.siteId);
    final siteName = runtime?.info.name ?? incident.siteId;
    final canSelectServer =
        runtime != null &&
        runtime.info.servers.isNotEmpty &&
        runtime.api.supports(SiteFeature.serverSwitch) &&
        runtime.api.supports(SiteFeature.healthCheck);
    final canSwitchSite = registry.allInfo.any(
      (info) => info.id != incident.siteId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('站点连接'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.errorContainer,
                          ),
                          child: Icon(
                            Icons.cloud_off_outlined,
                            size: 40,
                            color: colors.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '$siteName 暂时无法连接',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          incident.serverIds.isEmpty
                              ? '当前没有可用的服务器'
                              : '已检查 ${incident.serverIds.length} 个服务器，均未响应',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        if (_retryMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _retryMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _isRetrying
                                ? null
                                : () => _retry(incident),
                            icon: _isRetrying
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isRetrying ? '正在检测' : '重新检测'),
                          ),
                        ),
                        if (canSelectServer) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _selectServer(incident),
                              icon: const Icon(Icons.dns_outlined),
                              label: const Text('选择服务器'),
                            ),
                          ),
                        ],
                        if (canSwitchSite) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _selectSite(incident),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('切换站点'),
                          ),
                        ],
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: () => _leaveErrorPage(
                            null,
                            destination: AppRoutes.localMedia,
                          ),
                          icon: const Icon(Icons.folder_outlined),
                          label: const Text('使用本地媒体'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
