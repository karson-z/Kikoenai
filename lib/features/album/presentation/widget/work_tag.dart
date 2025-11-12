import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:provider/provider.dart';

enum TagType {
  normal,
  author,
  category,
  status,
}

/// 自定义标签行
class TagRow extends StatelessWidget {
  final List<String> tags;
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
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final vm = context.watch<ThemeViewModel>();
    final isDark = vm.themeMode == ThemeMode.dark;

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

  Widget _buildTag(String tag, bool isDark) {
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
      alignment: Alignment.center, // ✅ 文字居中
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: fs, color: textColor, height: 1),
        textAlign: TextAlign.center, // ✅ 文字居中
      ),
    );
  }
}
