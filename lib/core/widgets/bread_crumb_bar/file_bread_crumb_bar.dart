import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/provider/file_bread_crumb_bar.dart';

class BreadcrumbBar extends ConsumerWidget {
  const BreadcrumbBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final breadcrumbs = ref.watch(breadcrumbProvider);
    final notifier = ref.read(breadcrumbProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 根目录图标 (Home)
            InkWell(
              onTap: () => notifier.jumpTo(-1),
              borderRadius: BorderRadius.circular(4),
              child: Icon(
                Icons.home_outlined,
                size: 18,
                color: breadcrumbs.isEmpty ? Colors.blue : Colors.grey[500],
              ),
            ),

            // 动态路径节点
            for (int i = 0; i < breadcrumbs.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ),
              InkWell(
                onTap: () => notifier.jumpTo(i),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  breadcrumbs[i].title,
                  style: TextStyle(
                    fontSize: 13,
                    // 最后一级显示当前层级的高亮色，前面的层级显示可点击的蓝色
                    color: i == breadcrumbs.length - 1
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.blue,
                    fontWeight: i == breadcrumbs.length - 1
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}