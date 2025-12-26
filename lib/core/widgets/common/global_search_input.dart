import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme_view_model.dart';

class GlobalSearchInput extends ConsumerWidget {
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool autoFocus;
  final TextEditingController? controller;

  const GlobalSearchInput({
    super.key,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.controller,
    this.hintText = '搜索内容...',
    this.borderRadius = 25,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(explicitDarkModeProvider);
    final isButtonMode = onTap != null;

    final bgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      // 这里的 onTap 现在可以被正确触发了
      onTap: isButtonMode ? onTap : null,
      behavior: HitTestBehavior.opaque, // 确保点击空白区域也能触发
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: padding,
          child: IgnorePointer(
            ignoring: isButtonMode,
            child: TextField(
              controller: controller,
              readOnly: isButtonMode,
              onSubmitted: isButtonMode ? null : onSubmitted,
              onChanged: isButtonMode ? null : onChanged,
              autofocus: autoFocus,
              showCursor: !isButtonMode,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: iconColor),
                suffixIcon: (controller != null && !isButtonMode)
                    ? _ClearButton(controller: controller!, onChanged: onChanged)
                    : null,
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _ClearButton({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();

        return IconButton(
          icon: const Icon(Icons.clear, size: 18),
          color: Colors.grey,
          onPressed: () {
            controller.clear();
            onChanged?.call("");
          },
        );
      },
    );
  }
}