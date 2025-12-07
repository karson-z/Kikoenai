import 'package:flutter/material.dart';

class AppToast {
  static void show(
      BuildContext context,
      String message, {
        SnackBarAction? action,
        Duration duration = const Duration(seconds: 4),
        Color? backgroundColor,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 普通消息
  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.blue.withOpacity(0.9),
    );
  }

  // 成功
  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green.withOpacity(0.9),
    );
  }

  // 警告
  static void warning(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.orange.withOpacity(0.9),
    );
  }

  // 错误
  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.red.withOpacity(0.9),
    );
  }
}
