import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/webdav_connection_controller.dart';

class WebDavConnectionForm extends ConsumerStatefulWidget {
  const WebDavConnectionForm({super.key});

  @override
  ConsumerState<WebDavConnectionForm> createState() =>
      _WebDavConnectionFormState();
}

class _WebDavConnectionFormState extends ConsumerState<WebDavConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serverController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _rootPathController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(webDavConnectionControllerProvider);
    _serverController = TextEditingController(text: saved.serverUrl);
    _usernameController = TextEditingController(text: saved.username);
    _passwordController = TextEditingController();
    _rootPathController = TextEditingController(text: saved.rootPath);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _rootPathController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(webDavConnectionControllerProvider.notifier)
        .connect(
          WebDavConnectionConfig(
            serverUrl: _serverController.text,
            username: _usernameController.text,
            password: _passwordController.text,
            rootPath: _rootPathController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webDavConnectionControllerProvider);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '连接 WebDAV',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    controller: _serverController,
                    enabled: !state.isConnecting,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.url],
                    decoration: const InputDecoration(
                      labelText: 'WebDAV 地址',
                      hintText: 'https://example.com/dav/',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '请输入 WebDAV 地址'
                        : null,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !state.isConnecting,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: '账号',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !state.isConnecting,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: '密码',
                      helperText: '密码仅保留在本次运行内',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: state.isConnecting
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _rootPathController,
                    enabled: !state.isConnecting,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '起始目录',
                      hintText: '/',
                      prefixIcon: Icon(Icons.folder_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _connect(),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: state.isConnecting ? null : _connect,
                      icon: state.isConnecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_done_outlined),
                      label: Text(state.isConnecting ? '正在连接' : '连接'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
