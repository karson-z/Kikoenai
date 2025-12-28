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
  final double? fontSize;
  final EdgeInsets? padding;
  final double? spacing;
  final double? borderRadius;

  const TagRow({
    super.key,
    required this.tags,
    this.type = TagType.tag,
    this.fontSize,
    this.padding,
    this.spacing,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final isDark = ref.watch(explicitDarkModeProvider);
    final categoryController = ref.read(categoryUiProvider.notifier);

    return SizedBox(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: tags.map((tag) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque, // 阻止事件冒泡到卡片
                onTap: () {
                  debugPrint("点击了标签 类型:$type 名称:${tag.name}");

                  categoryController.toggleTag(type.stringValue, tag.name,refreshData: true);
                  context.go(AppRoutes.category);
                },
                child: Container(
                  margin: EdgeInsets.only(right: spacing ?? 6),
                  child: _buildTag(tag, isDark),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(dynamic tag, bool isDark) {
    final fs = fontSize ?? 12;
    final pad = padding ?? const EdgeInsets.all(6);
    final radius = borderRadius ?? 12;

    Color bgColor;
    Color textColor;

    switch (type) {
      case TagType.va:
        bgColor = Colors.green.withAlpha(20);
        textColor = Colors.green;
        break;
      case TagType.tag:
      default:
        bgColor = Colors.grey.withAlpha(20);
        textColor = isDark ? Colors.white : Colors.black87;
        break;
    }

    return Container(
      padding: pad,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        tag.name ?? tag.toString(),
        style: TextStyle(fontSize: fs, color: textColor, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}
