import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final BorderRadius? borderRadius;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon:
              Icon(prefixIcon, color: theme.colorScheme.onSurfaceVariant),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: theme.colorScheme.onSurface.withAlpha(10),
          border: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          // 增加内边距以确保悬浮label不会被遮挡
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          // 设置label行为，确保悬浮时不被遮挡
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          // 为label设置不透明背景，确保不会被输入框背景遮挡
          labelStyle: TextStyle(backgroundColor: theme.colorScheme.surface)),
      obscureText: obscureText,
      enabled: enabled,
    );
  }
}
