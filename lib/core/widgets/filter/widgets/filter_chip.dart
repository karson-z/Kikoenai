import 'package:flutter/material.dart';

/// chip 的四种形态
enum FilterChipStyle {
  /// 灰区/横条中的已选项：主色描边 + 可移除（×）
  selected,

  /// 选项网格中的包含态：主色描边 + 主色文字
  include,

  /// 排除态：红色描边 + 删除线
  exclude,

  /// 无已选时的维度快捷入口：弱化描边
  ghost,
}

/// 筛选 chip：覆盖「已选摘要 / 包含 / 排除 / 快捷入口」四种形态。
/// 纯展示组件，不依赖任何 provider。
class InlineFilterChip extends StatelessWidget {
  const InlineFilterChip({
    super.key,
    required this.label,
    required this.style,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.height = 32.0,
    this.expand = false,
    this.showIcon = false,
  });

  final String label;
  final FilterChipStyle style;

  /// 主体点击（移除 × 之外的区域）
  final VoidCallback? onTap;

  /// 长按（选项网格中用于直达排除态）
  final VoidCallback? onLongPress;

  /// 已选或排除态的 × 点击回调
  final VoidCallback? onRemove;

  final double height;

  /// true 时横向撑满（网格单元），false 时按内容收缩（Wrap / 横向列表）
  final bool expand;

  /// 是否在文字前显示搜索小图标（关键字 chip 用）
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    const excludeColor = Color(0xFFFF4D4F);

    final Color borderColor;
    final Color textColor;
    Color bgColor = Colors.transparent;
    var decoration = TextDecoration.none;

    switch (style) {
      case FilterChipStyle.selected:
      case FilterChipStyle.include:
        borderColor = primary;
        textColor = primary;
        bgColor = primary.withValues(alpha: 0.1);
      case FilterChipStyle.exclude:
        borderColor = excludeColor.withValues(alpha: 0.55);
        textColor = excludeColor;
        bgColor = excludeColor.withValues(alpha: 0.08);
        decoration = TextDecoration.lineThrough;
      case FilterChipStyle.ghost:
        borderColor = isDark
            ? const Color(0xFF3A4048)
            : const Color(0xFFD8DCE2);
        textColor = isDark ? const Color(0xFF8A919C) : const Color(0xFFA6ADB8);
    }

    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        height: 1.2,
        color: textColor,
        fontWeight: style == FilterChipStyle.ghost
            ? FontWeight.normal
            : FontWeight.w600,
        decoration: decoration,
        decorationColor: excludeColor,
      ),
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showIcon) ...[
          Icon(Icons.search, size: 12, color: textColor),
          const SizedBox(width: 3),
        ],
        Flexible(child: labelWidget),
        if ((style == FilterChipStyle.selected ||
                style == FilterChipStyle.exclude) &&
            onRemove != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: style == FilterChipStyle.exclude
                    ? excludeColor
                    : primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 9, color: Colors.white),
            ),
          ),
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: content,
      ),
    );
  }
}
