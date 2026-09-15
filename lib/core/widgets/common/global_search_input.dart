import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme_view_model.dart';

/// 通用搜索输入框。
///
/// 尺寸与对齐全部由本组件自身负责：
/// * 高度用 [height]、宽度用 [width]（不传则由父级约束，如 `Expanded`）；
///   调用方**不需要**再套 `SizedBox` 约束大小；
/// * 内部不使用 [InputDecoration] 的 `prefixIcon`/`suffixIcon`：图标槽自带
///   最小 48 高约束，会让输入区与图标各按自己的盒子对齐，这正是
///   「hint 无法垂直居中」「图标位置调不动」的根因。这里改用 [Row] + [Center]
///   手动排布，文字始终垂直居中，图标由 [leading]/[leadingPadding] 精确控制。
///
/// 两种形态：
/// * 编辑态（[onTap] 为 null）：可输入，回调 [onChanged]/[onSubmitted]，
///   有 [controller] 时显示清除按钮；
/// * 按钮态（[onTap] 非 null）：只读并忽略输入，整块点击回调 [onTap]，
///   用于「点一下跳转搜索页」的假输入框。
class GlobalSearchInput extends ConsumerWidget {
  const GlobalSearchInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = '搜索内容...',
    this.fontSize,
    this.width,
    this.height = 44,
    this.borderRadius = 25,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.leading,
    this.iconSize = 20,
    this.iconColor,
    this.leadingPadding = const EdgeInsets.only(right: 8),
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autoFocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;

  /// 输入文字与提示文字共用的字号；null 时沿用主题默认。
  final double? fontSize;

  /// 固定宽度；null 表示由父级约束决定。
  final double? width;

  /// 固定高度：由组件自身控制，调用方无需外层约束。
  final double height;

  final double borderRadius;

  /// 输入框整体内边距（前置图标、输入区、清除按钮都排在其内）。
  final EdgeInsetsGeometry padding;

  /// 前置图标槽；null 时显示默认放大镜（用 [iconSize]/[iconColor]），
  /// 传 `SizedBox.shrink()` 可隐藏，传任意 Widget 可完全自定义。
  final Widget? leading;

  final double iconSize;

  /// 前置图标颜色；null 时跟随明暗主题的灰阶。
  final Color? iconColor;

  /// 前置图标与其后输入区的间距。
  final EdgeInsetsGeometry leadingPadding;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 非空即为按钮态：只读并把整块点击交给它。
  final VoidCallback? onTap;

  final bool autoFocus;

  bool get _isButtonMode => onTap != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);
    final bgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final effectiveIconColor =
        iconColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    // contentPadding 归零 + isDense：TextField 自身高度即文字行高，
    // 再由外层 Center 垂直居中，hint 与输入文字始终同一位置。
    final Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: _isButtonMode,
      showCursor: !_isButtonMode,
      autofocus: autoFocus,
      onChanged: _isButtonMode ? null : onChanged,
      onSubmitted: _isButtonMode ? null : onSubmitted,
      onTapOutside: _isButtonMode ? null : (_) => focusNode?.unfocus(),
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: fontSize,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: fontSize),
        border: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      // 空白区域也可点击（按钮态下整块都是点击目标）
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: leadingPadding,
              child:
                  leading ??
                  Icon(Icons.search, size: iconSize, color: effectiveIconColor),
            ),
            Expanded(
              child: IgnorePointer(
                // 按钮态下让点击穿透到外层 GestureDetector
                ignoring: _isButtonMode,
                child: Center(child: field),
              ),
            ),
            if (controller != null && !_isButtonMode)
              _ClearButton(
                controller: controller!,
                onChanged: onChanged,
                iconSize: (height * 0.45).clamp(14.0, 20.0),
              ),
          ],
        ),
      ),
    );
  }
}

/// 紧凑型清除按钮：不用 [IconButton]（其默认最小 48×48 会撑坏低高度输入框），
/// 尺寸随输入框高度缩放。
class _ClearButton extends StatelessWidget {
  const _ClearButton({
    required this.controller,
    required this.iconSize,
    this.onChanged,
  });

  final TextEditingController controller;
  final double iconSize;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.clear();
            onChanged?.call('');
          },
          child: Center(
            child: SizedBox(
              width: iconSize + 10,
              height: iconSize + 10,
              child: Icon(Icons.clear, size: iconSize, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
