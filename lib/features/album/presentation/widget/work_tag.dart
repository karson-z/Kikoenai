import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_view_model.dart';

enum TagType {
  normal,
  author,
  category,
  status,
}

class TagRow extends ConsumerWidget {
  final List<dynamic> tags;
  final TagType type;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? spacing;
  final double? borderRadius;

  /// 新增：标签点击回调
  final void Function(dynamic tag)? onTagTap;

  const TagRow({
    super.key,
    required this.tags,
    this.type = TagType.normal,
    this.fontSize,
    this.padding,
    this.spacing,
    this.borderRadius,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final themeState = ref.watch(themeNotifierProvider);
    final isDark = themeState.maybeWhen(
      data: (value) => value.mode == ThemeMode.dark,
      orElse: () => false,
    );

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
                onTap: () => onTagTap?.call(tag),
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
      case TagType.author:
        bgColor = Colors.green.withAlpha(20);
        textColor = Colors.green;
        break;
      case TagType.category:
        bgColor = Colors.blue.withAlpha(10);
        textColor = Colors.blue;
        break;
      case TagType.status:
        bgColor = Colors.orange.withAlpha(10);
        textColor = Colors.orange;
        break;
      case TagType.normal:
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
