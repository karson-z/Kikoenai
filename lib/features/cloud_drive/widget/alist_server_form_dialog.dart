import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

Future<ServerInfo?> showAlistServerFormDialog(
  BuildContext context, {
  ServerInfo? initialValue,
}) {
  return showDialog<ServerInfo>(
    context: context,
    builder: (_) => AlistServerFormDialog(initialValue: initialValue),
  );
}

class AlistServerFormDialog extends StatefulWidget {
  const AlistServerFormDialog({super.key, this.initialValue});

  final ServerInfo? initialValue;

  @override
  State<AlistServerFormDialog> createState() => _AlistServerFormDialogState();
}

class _AlistServerFormDialogState extends State<AlistServerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _urlController;
  late bool _useProxy;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _urlController = TextEditingController(
      text: initial?.resolvedBaseUrl ?? '',
    );
    _useProxy = initial?.useProxy ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入 AList 地址';
    try {
      AsmrGaySiteApi.normalizeBaseUrl(
        ServerInfo(id: 'validate', baseUrl: value, label: 'validate'),
      );
      return null;
    } on FormatException catch (error) {
      return error.message;
    } catch (_) {
      return 'AList 地址无效';
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final initial = widget.initialValue;
    final temporary = ServerInfo(
      id: initial?.id ?? _newServerId(),
      baseUrl: _urlController.text.trim(),
      label: _labelController.text.trim().isEmpty
          ? 'AList'
          : _labelController.text.trim(),
      isDefault: initial?.isDefault ?? false,
      useProxy: _useProxy,
    );
    final normalizedUrl = AsmrGaySiteApi.normalizeBaseUrl(temporary);
    final uri = Uri.parse(normalizedUrl);
    Navigator.of(context).pop(
      ServerInfo(
        id: temporary.id,
        baseUrl: normalizedUrl,
        label: _labelController.text.trim().isEmpty
            ? uri.host
            : temporary.label,
        isDefault: temporary.isDefault,
        useProxy: temporary.useProxy,
      ),
    );
  }

  String _newServerId() =>
      'alist-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  @override
  Widget build(BuildContext context) {
    return KikoenaiAlertDialog(
      titleText: widget.initialValue == null ? '添加 AList 域名' : '编辑 AList 域名',
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '留空时使用域名',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'AList 地址',
                  hintText: 'https://alist.example.com',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                validator: _validateUrl,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('使用系统代理'),
                value: _useProxy,
                onChanged: (value) => setState(() => _useProxy = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        KikoenaiAlertDialog.textAction(
          context,
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
        KikoenaiAlertDialog.textAction(
          context,
          label: '保存',
          isConfirm: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
