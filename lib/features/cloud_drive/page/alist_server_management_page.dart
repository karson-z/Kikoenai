import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../provider/alist_server_provider.dart';
import '../widget/alist_server_form_dialog.dart';

enum _ServerAction { edit, delete }

class AlistServerManagementPage extends ConsumerStatefulWidget {
  const AlistServerManagementPage({super.key});

  @override
  ConsumerState<AlistServerManagementPage> createState() =>
      _AlistServerManagementPageState();
}

class _AlistServerManagementPageState
    extends ConsumerState<AlistServerManagementPage> {
  bool _isSaving = false;

  Future<void> _run(Future<void> Function() operation) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await operation();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_describeError(error))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addServer() async {
    final server = await showAlistServerFormDialog(context);
    if (server == null || !mounted) return;
    await _run(() => ref.read(alistServerControllerProvider).upsert(server));
  }

  Future<void> _editServer(ServerInfo server) async {
    final updated = await showAlistServerFormDialog(
      context,
      initialValue: server,
    );
    if (updated == null || !mounted) return;
    await _run(
      () => ref
          .read(alistServerControllerProvider)
          .upsert(updated, originalServerId: server.id),
    );
  }

  Future<void> _deleteServer(ServerInfo server) async {
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '删除域名',
      content: '确定删除“${server.label}”吗？',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;
    await _run(() => ref.read(alistServerControllerProvider).remove(server.id));
  }

  Future<void> _restoreBuiltInServers() async {
    final confirmed = await KikoenaiAlertDialog.confirm(
      context,
      title: '恢复内置域名',
      content: '当前自定义列表将被内置 AList 域名替换。',
      confirmLabel: '恢复',
    );
    if (!confirmed || !mounted) return;
    await _run(ref.read(alistServerControllerProvider).restoreBuiltInServers);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alistServerStateProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AList 域名'),
        actions: [
          IconButton(
            tooltip: '添加域名',
            onPressed: _isSaving ? null : _addServer,
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            enabled: !_isSaving,
            onSelected: (_) => _restoreBuiltInServers(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'restore', child: Text('恢复内置域名')),
            ],
          ),
        ],
        bottom: _isSaving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: state.servers.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
        itemBuilder: (context, index) {
          final server = state.servers[index];
          final isCurrent = server.id == state.currentServer.id;
          return ListTile(
            enabled: !_isSaving,
            leading: Icon(
              isCurrent
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              server.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              server.resolvedBaseUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: isCurrent
                ? null
                : () => _run(
                    () => ref
                        .read(alistServerControllerProvider)
                        .switchTo(server.id),
                  ),
            trailing: PopupMenuButton<_ServerAction>(
              tooltip: '域名操作',
              onSelected: (action) => switch (action) {
                _ServerAction.edit => _editServer(server),
                _ServerAction.delete => _deleteServer(server),
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ServerAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('编辑'),
                  ),
                ),
                PopupMenuItem(
                  value: _ServerAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('删除'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _describeError(Object error) {
    if (error is FormatException) return error.message;
    if (error is ArgumentError) return error.message?.toString() ?? '配置无效';
    if (error is StateError) return error.message;
    return '保存 AList 域名失败';
  }
}
