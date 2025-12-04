import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/error_banner.dart';
import 'package:kikoenai/core/widgets/message.dart';
import '../view_models/provider/auth_provider.dart';

class AuthDialog extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const AuthDialog({super.key, this.onSuccess});

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<AuthDialog> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
    });
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(authNotifierProvider.notifier);

    if (_accountController.text.isEmpty) {
      _showError('请输入账号');
      return;
    }

    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      _showError('密码长度至少6位');
      return;
    }

    if (_isRegisterMode) {
      // 如果你有注册方法，可以调用 notifier.register(...)，否则提示
      _showError('注册功能暂未实现');
    } else {
      final success = await notifier.login(
        _accountController.text,
        _passwordController.text
      );

      if (success) {
        _showSuccess('登录成功');
        widget.onSuccess?.call();
      } else {
        _showError('登录失败');
      }
    }
  }

  void _showError(String message) {
    Message.show(context: context, message: message, type: MessageType.error);
  }

  void _showSuccess(String message) {
    Message.show(context: context, message: message, type: MessageType.success);
  }

  @override
  Widget build(BuildContext context) {
    // 监听错误并弹出消息
    ref.listen(authNotifierProvider, (prev, next) {
      next.whenOrNull(
        data: (auth) {
          if (auth.error != null) {
            Message.show(
              context: context,
              message: auth.error!,
              type: MessageType.error,
            );
          }
        },
        error: (err, _) {
          Message.show(
            context: context,
            message: err.toString(),
            type: MessageType.error,
          );
        },
      );
    });

    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _isRegisterMode ? '用户注册' : '用户登录',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      TextField(
                        controller: _accountController,
                        decoration: InputDecoration(
                          labelText: '账号',
                          hintText: '请输入账号',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        enabled: !authState.isLoading,
                      ),
                      Divider(
                          height: 1,
                          color: theme.dividerColor.withAlpha(50)),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: '密码',
                          hintText: '请输入密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        enabled: !authState.isLoading,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white))
                    : Text(
                  _isRegisterMode ? '注册' : '登录',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: authState.isLoading ? null : _toggleMode,
                  child: Text(
                    _isRegisterMode ? '已有账号？点击登录' : '没有账号？点击注册',
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
