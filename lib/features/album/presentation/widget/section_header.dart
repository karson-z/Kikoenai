import 'package:flutter/material.dart';

/// 通用标题 + 更多按钮 的 Sliver 标题组件
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  const SectionHeader({
    super.key,
    required this.title,
    this.onMore,
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
                  Text(
                    '更多',
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
