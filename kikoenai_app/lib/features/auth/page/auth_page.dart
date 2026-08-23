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

  // 状态控制
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380), // 稍微收窄一点，让内容更紧凑
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- LOGO 区域 ---
                    SimpleExtendedImage(
                      Assets.images.muzumi.path,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      shape: BoxShape.circle,
                    ),
                    const SizedBox(height: 16), // 缩小间距
                    // --- 标题动画 ---
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isLoginMode ? "欢迎回来" : "创建账户",
                        key: ValueKey(isLoginMode),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24), // 直接过渡到输入框，去掉冗余副标题
                    // --- 合并后的输入框组 ---
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // 账号框
                          _buildTextField(
                            controller: _usernameController,
                            hintText: '用户名',
                            icon: Icons.person_outline_rounded,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? '请输入用户名'
                                : (value.length < 2 ? '用户名太短' : null),
                          ),
                          // 极简分割线
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                            indent: 48, // 让分割线避开图标区域，显得更精致
                          ),
                          // 密码框
                          _buildTextField(
                            controller: _passwordController,
                            hintText: '密码',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- 核心操作按钮 ---
                    SizedBox(
                      height: 48, // 稍微调小一点高度，配合紧凑的布局
                      child: FilledButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => _submit(isLoginMode),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  isLoginMode ? '登录' : '注册',
                                  key: ValueKey(isLoginMode),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- 切换模式 ---
                    if (canLogin && canRegister)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLoginMode ? "还没有账号? " : "已有账号? ",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: authState.isLoading ? null : _toggleMode,
                            child: Text(
                              isLoginMode ? "去注册" : "去登录",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 封装通用的无边框输入框（依靠外层 Container 提供视觉边界）
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText, // 改用 hintText，避免 label 浮动占用垂直空间
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
        suffixIcon: isPassword
            ? IconButton(
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
        filled: false, // 取消独立背景填充
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        // 彻底移除所有自带边框
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        errorStyle: TextStyle(color: colorScheme.error, height: 0.8), // 紧凑的错误提示
      ),
      validator: validator,
    );
  }
}
