import 'package:flutter/material.dart';

import '../../core/model/file_node.dart';

class NodeStatusPill extends StatelessWidget {
  final NodeStatus status;

  const NodeStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // normal 状态下不显示胶囊
    if (status == NodeStatus.normal) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    String text;
    Widget? icon;

    switch (status) {
      case NodeStatus.parsing:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = '解析中';
        icon = Container(
          margin: const EdgeInsets.only(right: 4),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
        );
        break;
      case NodeStatus.pending:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade600;
        text = '待解析';
        break;
      case NodeStatus.parsed:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = '已解析';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon,
          Text(
            text,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}