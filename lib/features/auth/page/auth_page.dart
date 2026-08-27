import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/service/site/site_availability.dart';
import '../provider/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();

  // 文本控制器
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;

  // 状态控制
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit(bool isLoginMode) {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);

    if (isLoginMode) {
      notifier.login(username, password);
    } else {
      notifier.register(username, password);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final availableSurfaces = ref.watch(availableSurfacesProvider);
    final canLogin = availableSurfaces.contains(AppSurface.loginAction);
    final canRegister = availableSurfaces.contains(AppSurface.registerAction);
    final isLoginMode = _isLogin ? canLogin || !canRegister : !canRegister;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 监听状态，处理错误和跳转
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error.toString().replaceAll('Exception: ', ''),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            backgroundColor: colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else if (next.value?.token != null) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    });

    if (!canLogin && !canRegister) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('当前站点不支持账户功能')),
      );
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              child: Container(
                                width: 76,
                                height: 76,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: SimpleExtendedImage(
                                  Assets.icons.appIcon,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Column(
                                key: ValueKey(isLoginMode),
                                children: [
                                  Text(
                                    isLoginMode ? '欢迎回来' : '创建账户',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isLoginMode ? '登录你的账户以继续' : '填写账户信息完成注册',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildFieldLabel('用户名'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _usernameController,
                              hintText: '请输入用户名',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              onFieldSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? '请输入用户名'
                                  : (value.length < 2 ? '用户名太短' : null),
                            ),
                            const SizedBox(height: 20),
                            _buildFieldLabel('密码'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              hintText: '请输入密码',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: [
                                isLoginMode
                                    ? AutofillHints.password
                                    : AutofillHints.newPassword,
                              ],
                              onFieldSubmitted: authState.isLoading
                                  ? null
                                  : (_) => _submit(isLoginMode),
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? '请输入密码'
                                  : (value.length < 6 ? '密码不能少于6位' : null),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => _submit(isLoginMode),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Text(
                                          isLoginMode ? '登录' : '注册',
                                          key: ValueKey(isLoginMode),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (canLogin && canRegister) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLoginMode ? '还没有账号？' : '已有账号？',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _toggleMode,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 44),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      isLoginMode ? '去注册' : '去登录',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildFieldLabel(String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    FocusNode? focusNode,
    bool isPassword = false,
    bool obscureText = false,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: isPassword
          ? TextInputType.visiblePassword
          : TextInputType.text,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 21),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: obscureText ? '显示密码' : '隐藏密码',
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        errorStyle: TextStyle(color: colorScheme.error),
      ),
      validator: validator,
    );
  }
}
