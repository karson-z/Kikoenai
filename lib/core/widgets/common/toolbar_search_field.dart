import 'package:flutter/material.dart';

import 'search_field_style.dart';

class ToolbarSearchField extends StatelessWidget {
  const ToolbarSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          inherit: false,
          color: textColor,
          fontFamily: theme.textTheme.bodyMedium?.fontFamily,
          fontSize: 14,
          textBaseline: TextBaseline.alphabetic,
          height: 1,
          letterSpacing: 0,
        ),
        strutStyle: const StrutStyle(
          fontSize: 14,
          height: 1,
          forceStrutHeight: true,
        ),
        cursorColor: colorScheme.primary,
        cursorHeight: 16,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            inherit: false,
            color: secondaryColor,
            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
            fontSize: 14,
            textBaseline: TextBaseline.alphabetic,
            height: 1,
            letterSpacing: 0,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: secondaryColor,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: '清空搜索',
                    color: secondaryColor,
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClear,
                  ),
          ),
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 32,
            height: 36,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF242426) : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(appSearchBorderRadius),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => focusNode.unfocus(),
      ),
    );
  }
}
