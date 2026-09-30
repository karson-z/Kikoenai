import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kikoenai/core/service/file/local_batch_rename.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class BatchRenameDialog extends StatefulWidget {
  const BatchRenameDialog({super.key, required this.nodes});

  final List<FileNode> nodes;

  static Future<bool> show(BuildContext context, List<FileNode> nodes) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => BatchRenameDialog(nodes: nodes),
        ) ??
        false;
  }

  @override
  State<BatchRenameDialog> createState() => _BatchRenameDialogState();
}

class _BatchRenameDialogState extends State<BatchRenameDialog> {
  final _service = const LocalBatchRename();
  final _prefix = TextEditingController();
  final _suffix = TextEditingController();
  final _find = TextEditingController();
  final _replace = TextEditingController();
  final _manual = <String, TextEditingController>{};
  bool _individual = false;
  bool _number = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final node in widget.nodes) {
      _manual[node.keyId] =
          TextEditingController(text: _service.baseName(node));
    }
    for (final controller in [
      _prefix,
      _suffix,
      _find,
      _replace,
      ..._manual.values
    ]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() => _error = null);
  }

  @override
  void dispose() {
    for (final controller in [
      _prefix,
      _suffix,
      _find,
      _replace,
      ..._manual.values
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<RenameProposal> _proposals() {
    return [
      for (var index = 0; index < widget.nodes.length; index++)
        RenameProposal(
            widget.nodes[index], _nameFor(widget.nodes[index], index)),
    ];
  }

  String _nameFor(FileNode node, int index) {
    var name = _individual
        ? _manual[node.keyId]!.text.trim()
        : _service.baseName(node);
    if (!_individual) {
      if (_find.text.isNotEmpty) {
        name = name.replaceAll(_find.text, _replace.text);
      }
      name = '${_prefix.text}$name${_suffix.text}';
      if (_number) name = '$name ${(index + 1).toString().padLeft(2, '0')}';
    }
    return '$name${_service.extension(node)}';
  }

  Future<void> _execute(List<RenameProposal> proposals) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.execute(proposals);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(result.succeeded.isNotEmpty);
      messenger.showSnackBar(SnackBar(
        content: Text(
            '重命名成功 ${result.succeeded.length} 项，失败 ${result.failed.length} 项'
            '${result.failed.isEmpty ? '' : '：${result.failed.values.first}'}'),
      ));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposals = _proposals();
    final validation = _service.validate(proposals);
    final changed =
        proposals.any((proposal) => proposal.newPath != proposal.oldPath);
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      child: SizedBox(
        width: math.min(size.width - 32, 620),
        height: math.min(size.height - 80, 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child:
                  Text('批量重命名', style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('规则')),
                  ButtonSegment(value: true, label: Text('逐项')),
                ],
                selected: {_individual},
                onSelectionChanged: (values) =>
                    setState(() => _individual = values.single),
              ),
            ),
            if (!_individual)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  _field(_prefix, '前缀'),
                  _field(_suffix, '后缀'),
                  _field(_find, '查找'),
                  _field(_replace, '替换为'),
                  FilterChip(
                    label: const Text('自动编号'),
                    selected: _number,
                    onSelected: (value) => setState(() => _number = value),
                  ),
                ]),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  final proposal = proposals[index];
                  final error = validation[proposal];
                  return ListTile(
                    dense: true,
                    title: _individual
                        ? TextField(
                            controller: _manual[proposal.node.keyId],
                            decoration: InputDecoration(
                              labelText: proposal.node.title,
                              suffixText: _service.extension(proposal.node),
                              errorText: error,
                              isDense: true,
                            ),
                          )
                        : Text(proposal.node.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: _individual
                        ? null
                        : Text(error ?? '→ ${proposal.newName}',
                            style: TextStyle(
                                color: error == null
                                    ? null
                                    : Theme.of(context).colorScheme.error)),
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('取消')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy || validation.isNotEmpty || !changed
                      ? null
                      : () => _execute(proposals),
                  child: Text(_busy ? '处理中' : '确认重命名'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => SizedBox(
        width: 125,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );
}
