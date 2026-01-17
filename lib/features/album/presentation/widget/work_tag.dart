import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';
import '../../../../core/enums/tag_enum.dart';
import '../../../../core/theme/theme_view_model.dart';

class TagRow extends ConsumerWidget {
  final List<dynamic> tags;
  final TagType type;

  const TagRow({
    super.key,
    required this.tags,
    this.type = TagType.tag,
  });

  // 常量定义
  static const double kTagFontSize = 10.0;
  static const double kTagBorderRadius = 4.0;
  static const EdgeInsets kTagPadding = EdgeInsets.symmetric(horizontal: 4);
  static const double kItemSpacing = 4.0;
  static const double kRowHeight = 22.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 判空快速返回，减少 Widget 树深度
    if (tags.isEmpty) return const SizedBox.shrink();

    final isDark = ref.watch(explicitDarkModeProvider);

    return SizedBox(
      height: kRowHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          // 3. 关键优化：使用 min，这样如果标签很少，Row 不会强行撑满整行宽度
          // 虽然在 SingleChildScrollView 里它默认就是 min，但显式声明是个好习惯
          mainAxisSize: MainAxisSize.min,
          children: tags.map((tag) {
            return _TagItem(
              tag: tag,
              type: type,
              isDark: isDark,
              ref: ref, // 将 ref 传递给子组件或者在 onTap 中使用 context.read (如果不用 riverpod generator)
            );
          }).toList(),
        ),
      ),
    );
  }
}

// 4. 将 TagItem 提取出来（可选），或者保持在原文件。
// 这里为了代码清晰，我们将 _buildTag 逻辑封装，
// 主要是为了让 onTap 里的逻辑更清晰。
class _TagItem extends StatelessWidget {
  final dynamic tag;
  final TagType type;
  final bool isDark;
  final WidgetRef ref;

  const _TagItem({
    required this.tag,
    required this.type,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case TagType.va:
        bgColor = Colors.green.withAlpha(25);
        textColor = Colors.green;
        break;
      case TagType.tag:
      default:
        bgColor = isDark ? Colors.white10 : Colors.grey.withAlpha(30);
        textColor = isDark ? Colors.white70 : Colors.black87;
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 在回调时读取 notifier，这是最安全的做法
        ref.read(categoryUiProvider.notifier).toggleTag(
            type.stringValue,
            tag.name,
            refreshData: true
        );
        context.go(AppRoutes.category);
      },
      child: Container(
        margin: const EdgeInsets.only(right: TagRow.kItemSpacing),
        padding: TagRow.kTagPadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(TagRow.kTagBorderRadius),
        ),
        child: Text(
          tag.name ?? tag.toString(),
          style: TextStyle(
            fontSize: TagRow.kTagFontSize,
            color: textColor,
            height: 1.1,
            leadingDistribution: TextLeadingDistribution.even,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}