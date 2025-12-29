import 'package:flutter/material.dart';

import '../common/kikoenai_dialog.dart';
// ⚠️ 必须引入你之前定义的 KikoenaiDialog 文件，因为我们需要访问 observer
// import 'package:kikoenai/core/widgets/dialog/kikoenai_dialog.dart';

class KikoenaiToast {
  // 私有构造，防止实例化
  KikoenaiToast._();

  /// 核心显示方法
  /// [message] 消息内容
  /// [context] 可选。如果不传，尝试使用 KikoenaiDialog.observer 全局查找 ScaffoldContext
  static void show({
    required String message,
    BuildContext? context,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    Color? foregroundColor,
    IconData? icon,
  }) {
    // 1. 获取上下文：优先使用传入的 -> 其次使用 Observer 追踪的 Scaffold 上下文
    // 注意：显示 SnackBar 必须要有 Scaffold 上下文，普通的 context 可能不行
    final ctx = context ?? KikoenaiDialog.observer.scaffoldContext;

    if (ctx == null || !ctx.mounted) {
      debugPrint('KikoenaiToast Error: No valid Scaffold context found to show toast.');
      return;
    }

    // 2. 隐藏当前的 SnackBar，防止堆积 (Debounce)
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();

    // 3. 构建内容 (图标 + 文本)
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: foregroundColor ?? Colors.white, size: 20),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            message,
            style: TextStyle(
              color: foregroundColor ?? Colors.white,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );

    // 4. 响应式布局参数
    final isDesktop = MediaQuery.sizeOf(ctx).width > 600;

    // 5. 显示
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: content,
        action: action,
        duration: duration,
        backgroundColor: backgroundColor ?? Colors.grey[900],
        behavior: SnackBarBehavior.floating, // 悬浮样式
        elevation: 6.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // 桌面端限制宽度，移动端使用 margin
        width: isDesktop ? 400 : null,
        margin: isDesktop ? null : const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== 快捷方法 ====================

  /// 普通提示
  static void info(
      String message, {
        BuildContext? context,
      }) {
    show(
      message: message,
      context: context,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info_outline,
    );
  }

  /// 成功提示
  static void success(
      String message, {
        BuildContext? context,
      }) {
    show(
      message: message,
      context: context,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
    );
  }

  /// 警告提示
  static void warning(
      String message, {
        BuildContext? context,
      }) {
    show(
      message: message,
      context: context,
      backgroundColor: Colors.orange.shade800,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// 错误提示
  static void error(
      String message, {
        BuildContext? context,
        SnackBarAction? action,
      }) {
    show(
      message: message,
      context: context,
      action: action,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
    );
  }
}