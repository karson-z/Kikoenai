import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
// 移除未使用的导入
import 'package:name_app/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool _isLoading = false;
  bool _isCheckingSize = false;

  Future<void> _handleCheckSize() async {
    setState(() {
      _isCheckingSize = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final all = prefs.getKeys();

      int totalBytes = 0;
      final Map<String, String> keyDetails = {};

      for (final key in all) {
        final value = prefs.get(key);
        final encoded = utf8.encode(jsonEncode(value));
        final size = encoded.length;
        keyDetails[key] = '$size bytes';
        totalBytes += size;
      }

      final totalKB = totalBytes / 1024;

      // 构建详细信息字符串
      final details = StringBuffer();
      details.writeln('总大小: ${totalKB.toStringAsFixed(2)} KB');
      details.writeln('----------------------------');
      keyDetails.forEach((key, value) {
        details.writeln('$key: $value');
      });
      details.writeln('----------------------------');

      if (totalKB > 512) {
        details.writeln('⚠️ 警告：SharedPreferences 超过 512KB，建议清理或改用数据库。');
      } else {
        details.writeln('✅ SharedPreferences 容量正常。');
      }

      // 显示详细信息弹窗
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('SharedPreferences 大小信息'),
            content: SingleChildScrollView(
              child: Text(details.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查大小失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isCheckingSize = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    // 显示确认对话框
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmLogout != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 创建服务实例
      final service = GetIt.I<AuthViewModel>();

      // 删除所有用户信息
      await service.logout().then((value) {
        if (value) {
          // 显示退出成功提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已退出登录')),
            );
          }
        } else {
          // 显示错误提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('退出失败')),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出过程中发生错误: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeViewModel>(); // 保留以确保主题变化时重建

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 用户信息区域占位
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child:
                        const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '用户名',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 功能按钮列表
            Column(
              children: [
                // 检查大小按钮
                ElevatedButton.icon(
                  onPressed: _isCheckingSize ? null : _handleCheckSize,
                  icon: const Icon(Icons.storage),
                  label: const Text('检查存储大小'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // 退出登录按钮
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isLoading || _isCheckingSize)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
