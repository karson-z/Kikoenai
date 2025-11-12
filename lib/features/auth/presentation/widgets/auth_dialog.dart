import 'package:flutter/material.dart';
import 'package:name_app/features/auth/data/model/login_params.dart';
import 'package:name_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import 'package:name_app/core/widgets/common/error_banner.dart';
import 'package:name_app/core/widgets/message.dart';

class AuthDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AuthDialog({super.key, this.onSuccess});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
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

  void _handleSubmit(AuthViewModel vm) async {
    if (_accountController.text.isEmpty) {
      _showError('请输入账号');
      return;
    }

    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      _showError('密码长度至少6位');
      return;
    }

    final params = {
      'account': _accountController.text,
      'pwd': _passwordController.text
    };

    if (_isRegisterMode) {
      await vm.register(params);
      if (vm.error == null) {
        _showSuccess('注册成功，请登录');
        _toggleMode();
      }
    } else {
      await vm.login(LoginParams(
          account: _accountController.text, pwd: _passwordController.text));
      if (vm.error == null) {
        _showSuccess('登录成功');
        widget.onSuccess?.call();
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
    final vm = context.watch<AuthViewModel>();
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
              // 标题
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

              if (vm.error != null) ...[
                const SizedBox(height: 11),
                ErrorBanner(message: vm.error!),
              ],

              // 输入框组
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      // 账号
                      AuthTextField(
                        controller: _accountController,
                        labelText: '账号',
                        hintText: '请输入账号',
                        prefixIcon: Icons.person_outline,
                        enabled: !vm.loading,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                          bottom: Radius.zero,
                        ),
                      ),
                      Divider(
                          height: 1, color: theme.dividerColor.withAlpha(50)),
                      // 密码
                      AuthTextField(
                        controller: _passwordController,
                        labelText: '密码',
                        hintText: '请输入密码',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        enabled: !vm.loading,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 登录/注册按钮
              ElevatedButton(
                onPressed: vm.loading ? null : () => _handleSubmit(vm),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: vm.loading
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

              // 切换登录/注册
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: vm.loading ? null : _toggleMode,
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
