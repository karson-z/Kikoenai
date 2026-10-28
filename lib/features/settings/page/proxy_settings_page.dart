import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/service/proxy/auto_proxy_service.dart';
import '../../../core/service/proxy/proxy_settings.dart';
import '../../../core/service/proxy/system_proxy_config.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_layout_tokens.dart';
import '../../../core/widgets/layout/app_toast.dart';

class ProxySettingsPage extends StatefulWidget {
  const ProxySettingsPage({super.key});

  @override
  State<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late ProxySettings _settings;
  late final TextEditingController _url;
  late final TextEditingController _testUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settings = ProxySettings.fromStorage(AppStorage.settingsBox);
    _url = TextEditingController(text: _settings.url);
    _testUrl = TextEditingController(text: _settings.testUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    _testUrl.dispose();
    super.dispose();
  }

  Future<void> _commit(ProxySettings settings) async {
    await settings.save(AppStorage.settingsBox);
    ProxyService.setManualSettings(settings);
    _settings = settings;
    if (mounted) setState(() {});
  }

  Future<void> _toggle(bool enabled) async {
    if (_busy) return;
    if (enabled && (!_settings.configured || _settings.endpoint == null)) {
      KikoenaiToast.info('请先保存并测试代理配置', context: context);
      return;
    }
    setState(() => _busy = true);
    try {
      await _commit(_settings.copyWith(enabled: enabled));
    } catch (_) {
      if (mounted) KikoenaiToast.error('保存代理设置失败', context: context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAndTest() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    final candidate = ProxySettings(
      url: _url.text.trim(),
      testUrl: _testUrl.text.trim().isEmpty
          ? ProxySettings.defaultTestUrl
          : _testUrl.text.trim(),
    );
    setState(() => _busy = true);
    try {
      // A changed address needs a new successful test before it can be enabled.
      await _commit(candidate);
      await candidate.testConnection();
      await _commit(candidate.copyWith(enabled: true, configured: true));
      if (mounted) KikoenaiToast.success('测试成功，已启用代理', context: context);
    } catch (_) {
      if (mounted) {
        KikoenaiToast.error('代理连接失败或设置未能保存，请检查后重试', context: context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络代理')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.layout.formMaxWidth),
          child: ListView(
            padding: EdgeInsets.all(context.layout.pageInset),
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用手动代理'),
                subtitle: const Text('开启后优先使用此代理；关闭后跟随系统代理设置'),
                value: _settings.isActive,
                onChanged: _busy ? null : _toggle,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _url,
                      enabled: !_busy,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: '代理地址',
                        hintText: 'http://127.0.0.1:7890',
                        helperText: '支持 HTTP 代理，填写主机和端口',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => ProxyEndpoint.parse(value) == null
                          ? '请输入有效的 http://host:port 或 host:port'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _testUrl,
                      enabled: !_busy,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: '测试地址',
                        hintText: ProxySettings.defaultTestUrl,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final uri = Uri.tryParse(value.trim());
                        return uri != null &&
                                ['http', 'https'].contains(uri.scheme) &&
                                uri.host.isNotEmpty &&
                                uri.userInfo.isEmpty
                            ? null
                            : '请输入有效的 HTTP 或 HTTPS 地址';
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _saveAndTest,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check),
                      label: Text(_busy ? '处理中…' : '保存并测试'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('保存并测试成功后自动启用。正在播放的内容不会中断，重新加载媒体后应用新配置。'),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                const Text('iOS 后台下载的代理变更需重新启动应用后生效。'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
