import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import '../../../../core/routes/app_routes.dart';
import '../view_models/provider/auth_provider.dart';

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
  bool _obscurePassword = true; // 控制密码是否隐藏

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);

    if (_isLogin) {
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating, // 悬浮样式更美观
          ),
        );
      } else if (next.value?.token != null) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      // 使用 Stack 放置背景层
      body: Stack(
        children: [
          // 2. 内容层
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 8, // 阴影深度
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24), // 大圆角
                ),
                color: Colors.white.withOpacity(0.95), // 微微透明的卡片
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 包裹内容
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- LOGO 区域 ---
                        const SimpleExtendedImage(
                          'assets/images/muzumi.jpg',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),

                        // --- 标题动画 ---
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isLogin ? "欢迎回来" : "创建账户",
                            key: ValueKey(_isLogin), // 关键：Key 变化触发动画
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? "请登录以继续" : "注册以开始体验",
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // --- 输入框：用户名 ---
                        _buildTextField(
                          controller: _usernameController,
                          label: '用户名',
                          icon: Icons.person_outline,
                          validator: (value) => (value == null || value.isEmpty)
                              ? '请输入用户名'
                              : (value.length < 2 ? '用户名太短' : null),
                        ),
                        const SizedBox(height: 16),

                        // --- 输入框：密码 ---
                        _buildTextField(
                          controller: _passwordController,
                          label: '密码',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) => (value == null || value.isEmpty)
                              ? '请输入密码'
                              : (value.length < 6 ? '密码长度不能少于6位' : null),
                        ),
                        const SizedBox(height: 32),

                        // --- 登录按钮 ---
                        SizedBox(
                          height: 56, // 更高的按钮方便点击
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _isLogin ? '登录' : '注册',
                                key: ValueKey(_isLogin),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- 切换模式 ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? "还没有账号? " : "已有账号? ",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            GestureDetector(
                              onTap: authState.isLoading ? null : _toggleMode,
                              child: Text(
                                _isLogin ? "去注册" : "去登录",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  /// 封装一个通用的输入框构建方法，保持代码整洁
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        )
            : null,
        // 使用 Filled 样式，看起来更现代
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // 默认无边框
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
      validator: validator,
    );
  }
}