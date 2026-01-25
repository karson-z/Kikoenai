import 'package:flutter/material.dart';

class AppActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap; // 如果为 null，则显示为禁用状态
  final Color color;
  final String? tooltip;
  final double iconSize;
  final double padding;
  final bool isLoading; // 新增：加载状态

  const AppActionButton({
    super.key,
    required this.icon,
    this.onTap,
    required this.color,
    this.tooltip,
    this.iconSize = 20.0,
    this.padding = 8.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 处理禁用状态的颜色
    final bool isDisabled = onTap == null;
    final Color effectiveColor = isDisabled ? Colors.grey.shade400 : color;

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isDisabled || isLoading) ? null : onTap,
        borderRadius: BorderRadius.circular(padding + iconSize), // 动态计算圆角
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            // 禁用时背景更淡，加载时保持原样
            color: effectiveColor.withOpacity(isDisabled ? 0.05 : 0.1),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          )
              : Icon(icon, size: iconSize, color: effectiveColor),
        ),
      ),
    );

    // 如果有提示文本，包裹 Tooltip
    if (tooltip != null && !isLoading) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}