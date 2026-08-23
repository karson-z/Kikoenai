import 'package:flutter/material.dart';

/// 通用标题 + 更多按钮 的 Sliver 标题组件
class SectionHeader extends StatelessWidget {
  final String title;
  final bool isShowMoreButton;
  final VoidCallback? onMore;

  /// 标题右侧的自定义控件（如布局切换按钮），位于"更多"右侧。
  final Widget? trailing;

  const SectionHeader({
    super.key,
    this.isShowMoreButton = false,
    required this.title,
    this.onMore,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  if (isShowMoreButton)
                    Text(
                      '更多',
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  const SizedBox(width: 3),
                  if (isShowMoreButton)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: color,
                    ),
                ],
              ),
            ),

            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
