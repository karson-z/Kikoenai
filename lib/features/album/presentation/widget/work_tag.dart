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

/// 自定义标签行，支持 Riverpod 主题监听
class TagRow extends ConsumerWidget {
  final List<dynamic> tags;
  final TagType type;
  final double? fontSize;
  final EdgeInsets? padding; // 内边距
  final double? spacing; // 标签之间间距
  final double? borderRadius;

  const TagRow({
    super.key,
    required this.tags,
    this.type = TagType.normal,
    this.fontSize,
    this.padding,
    this.spacing,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tags.isEmpty) return const SizedBox.shrink();

    // 监听主题状态
    final themeStateAsync = ref.watch(themeNotifierProvider);
    final isDark = themeStateAsync.maybeWhen(
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
            children: tags
                .map(
                  (tag) => Container(
                margin: EdgeInsets.only(right: spacing ?? 6),
                child: _buildTag(tag, isDark),
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(dynamic tag, bool isDark) {
    final fs = fontSize ?? 12;
    final pad = padding ?? const EdgeInsets.all(6);
    final radius = borderRadius ?? 12;

    // 根据类型设置背景色和文字色
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
      alignment: Alignment.center, // 文字居中
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        tag.name!,
        style: TextStyle(fontSize: fs, color: textColor, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}
