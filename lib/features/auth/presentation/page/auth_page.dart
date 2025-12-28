import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  // 控制当前模式：true = 登录, false = 注册
  bool _isLogin = true;

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

  /// 提交表单逻辑
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // 关闭软键盘
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final notifier = ref.read(authNotifierProvider.notifier);

    // 根据模式调用不同方法
    if (_isLogin) {
      notifier.login(username, password);
    } else {
      notifier.register(username, password);
    }
  }

  /// 切换登录/注册模式
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      // 切换时清空可能的错误提示，体验更好（可选）
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. 监听 AuthNotifier 的状态以控制 UI (Loading / Error)
    final authState = ref.watch(authNotifierProvider);

    // 2. 监听副作用 (Side Effects): 跳转或报错
    ref.listen(authNotifierProvider, (previous, next) {
      // 处理错误
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
      // 处理成功 (Token 存在即视为成功)
      else if (next.value?.token != null) {
        // 如果是注册成功，也可以选择先提示“注册成功”，再自动登录或跳转
        // 这里直接统一跳转到首页
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  _isLogin ? "欢迎回来" : "创建账户",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    if (value.length < 2) {
                      return '用户名长度不能少于2位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 6) {
                      return '密码长度不能少于6位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 主操作按钮 (登录/注册)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(
                      _isLogin ? '登录' : '注册',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 切换模式按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? "还没有账号? " : "已有账号? "),
                    TextButton(
                      onPressed: authState.isLoading ? null : _toggleMode,
                      child: Text(_isLogin ? "去注册" : "去登录"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}