import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/global_search_input.dart';

class SearchAppBar extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final Widget? leading;
  final VoidCallback? onLeadingTap;

  const SearchAppBar({
    Key? key,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
    this.hintText = '请输入关键字...',
    this.leading,
    this.onLeadingTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topPadding = MediaQuery.of(context).padding.top;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(
              top: topPadding + 12,
              left: 4,
              right: 16,
              bottom: 12
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeading(context),
              const SizedBox(width: 4),
              Expanded(
                child: GlobalSearchInput(
                  controller: controller,
                  hintText: hintText,
                  autoFocus: true,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 12),

              // --- 右侧搜索按钮 ---
              TextButton(
                onPressed: () {
                  if (onSubmitted != null) {
                    onSubmitted!(controller.text);
                  }
                  FocusScope.of(context).unfocus();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  "搜索",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading!;
    }
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onLeadingTap ?? () => Navigator.of(context).pop(),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}