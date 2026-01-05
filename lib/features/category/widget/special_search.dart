import 'package:flutter/material.dart';

import '../../../core/enums/age_rating.dart';
import '../../../core/enums/duration_enum.dart';
import '../../../core/enums/lang_enum.dart';
import '../../../core/enums/price_enum.dart';
import '../../../core/enums/rate_enum.dart';
import '../../../core/enums/sell_enum.dart';
import '../../../core/enums/tag_enum.dart';
import '../../../core/model/filter_option_item.dart';
import '../../../core/model/search_tag.dart'; // 确保引入 SearchTag

class AdvancedFilterPanel extends StatelessWidget {
  // --- 改动 1: 接收具体的标签列表，而不是整个 UI State ---
  final List<SearchTag> selectedTags;

  // --- 改动 2: 接收回调函数，而不是 Notifier ---
  final Function(String type, String name) onToggleTag;

  // 样式配置
  final Color fillColor;
  final Color textColor;

  const AdvancedFilterPanel({
    Key? key,
    required this.selectedTags,
    required this.onToggleTag,
    required this.fillColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 定义配置映射
    // 假设这些 Enum 都实现了 FilterOptionItem 接口
    final Map<TagType, List<FilterOptionItem>> filterConfig = {
      TagType.age: AgeRatingEnum.values,
      TagType.lang: LangEnum.values,
      TagType.duration: DurationEnum.values,
      TagType.rate: RateEnum.values,
      TagType.sell: SellEnum.values,
      TagType.price: PriceEnum.values,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: filterConfig.entries.map((entry) {
          return _buildSectionGroup(
            context,
            type: entry.key,
            options: entry.value,
          );
        }).toList(),
      ),
    );
  }

  /// 构建单个分组
  Widget _buildSectionGroup(
      BuildContext context, {
        required TagType type,
        required List<FilterOptionItem> options,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 分组标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(_getIconForType(type), size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                _getTitleForType(type),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800], // 标题颜色可以固定深色，或者传参
                ),
              ),
            ],
          ),
        ),
        // 2. 标签流
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((opt) => _buildSingleTag(type, opt)).toList(),
          ),
        ),
        const SizedBox(height: 16), // 组间距
        Divider(
            height: 1,
            color: Colors.grey.withOpacity(0.1),
            indent: 16,
            endIndent: 16),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建单个标签 UI
  Widget _buildSingleTag(TagType type, FilterOptionItem option) {
    // --- 改动 3: 使用 selectedTags 判断选中状态 ---
    final tagIndex = selectedTags.indexWhere(
          (t) => t.type == type.stringValue && t.name == option.value,
    );
    final isSelected = tagIndex != -1;
    final isExclude = isSelected ? selectedTags[tagIndex].isExclude : false;

    const errorColor = Color(0xFFFF4D4F);
    final activeColor = option.activeColor; // 假设 FilterOptionItem 有 activeColor

    Color bg;
    Color fg;
    Border? border;

    if (!isSelected) {
      bg = fillColor;
      fg = textColor;
      border = Border.all(color: Colors.transparent);
    } else if (isExclude) {
      bg = errorColor.withOpacity(0.1);
      fg = errorColor;
      border = Border.all(color: errorColor);
    } else {
      bg = activeColor.withOpacity(0.1);
      fg = activeColor;
      border = Border.all(color: activeColor);
    }

    return InkWell(
      // --- 改动 4: 调用回调函数 ---
      onTap: () => onToggleTag(type.stringValue, option.value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: border,
        ),
        child: Text(
          option.label, // 假设 FilterOptionItem 有 label
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(TagType type) {
    switch (type) {
      case TagType.age: return Icons.explicit;
      case TagType.lang: return Icons.language;
      case TagType.duration: return Icons.schedule;
      case TagType.rate: return Icons.star_border;
      case TagType.price: return Icons.attach_money;
      case TagType.sell: return Icons.local_fire_department;
      default: return Icons.label_outline;
    }
  }

  String _getTitleForType(TagType type) {
    switch (type) {
      case TagType.age: return "分级";
      case TagType.lang: return "语言";
      case TagType.duration: return "时长";
      case TagType.rate: return "评分";
      case TagType.price: return "价格";
      case TagType.sell: return "销量";
      default: return "其他";
    }
  }
}