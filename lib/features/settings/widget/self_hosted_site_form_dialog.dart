import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

Future<ServerInfo?> showSelfHostedSiteFormDialog(BuildContext context) {
  return showDialog<ServerInfo>(
    context: context,
    builder: (_) => const SelfHostedSiteFormDialog(),
  );
}

class SelfHostedSiteFormDialog extends StatefulWidget {
  const SelfHostedSiteFormDialog({super.key});

  @override
  State<SelfHostedSiteFormDialog> createState() =>
      _SelfHostedSiteFormDialogState();
}

class _SelfHostedSiteFormDialogState extends State<SelfHostedSiteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _urlController = TextEditingController();
  bool _useProxy = false;

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入站点地址';
    try {
      KikoeruSiteApi.webBaseUrlFor(
        ServerInfo(id: 'validate', baseUrl: value.trim(), label: 'validate'),
      );
      return null;
    } on FormatException catch (error) {
      return error.message;
    } catch (_) {
      return '站点地址无效';
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final temporary = ServerInfo(
      id: _newServerId(),
      baseUrl: _urlController.text.trim(),
      label: _labelController.text.trim().isEmpty
          ? 'Kikoeru'
          : _labelController.text.trim(),
      useProxy: _useProxy,
    );
    final normalizedUrl = KikoeruSiteApi.webBaseUrlFor(temporary);
    final uri = Uri.parse(normalizedUrl);
    Navigator.of(context).pop(
      ServerInfo(
        id: temporary.id,
        baseUrl: normalizedUrl,
        label: _labelController.text.trim().isEmpty
            ? uri.host
            : temporary.label,
        useProxy: temporary.useProxy,
      ),
    );
  }

  String _newServerId() =>
      'kikoeru-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  @override
  Widget build(BuildContext context) {
    return KikoenaiAlertDialog(
      titleText: '添加自建站',
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
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: '站点地址',
                  hintText: 'https://kikoeru.example.com',
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
