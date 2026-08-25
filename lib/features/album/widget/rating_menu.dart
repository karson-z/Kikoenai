import 'package:flutter/material.dart';

class RatingMetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const RatingMetaItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end, // 对齐底部
      children: [
        const SizedBox(width: 6),
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text, // 父组件负责处理括号 "($text)" 或直接传纯文本
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}