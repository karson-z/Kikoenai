import 'package:flutter/material.dart';

import '../../../core/enums/age_rating.dart';
import '../../../core/enums/duration_enum.dart';
import '../../../core/enums/lang_enum.dart';
import '../../../core/enums/price_enum.dart';
import '../../../core/enums/rate_enum.dart';
import '../../../core/enums/sell_enum.dart';
import '../../../core/enums/tag_enum.dart';
import '../../../core/model/filter_option_item.dart';
import '../presentation/viewmodel/provider/category_data_provider.dart';
import '../presentation/viewmodel/state/category_ui_state.dart';

class AdvancedFilterPanel extends StatelessWidget {
  final CategoryUiState uiState;
  final CategoryUiNotifier notifier;

  // 样式配置
  final Color fillColor;
  final Color textColor;
  final Color backgroundColor;

  const AdvancedFilterPanel({
    Key? key,
    required this.uiState,
    required this.notifier,
    required this.fillColor,
    required this.textColor,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ================= 配置区域 =================
// 在 AdvancedFilterPanel 的 build 方法中：

    final Map<TagType, List<FilterOptionItem>> filterConfig = {
      TagType.age: AgeRatingEnum.values,
      TagType.lang: LangEnum.values,
      TagType.duration: DurationEnum.values,
      TagType.rate: RateEnum.values,
      TagType.sell: SellEnum.values,
      TagType.price: PriceEnum.values,
    };

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: filterConfig.entries.map((entry) {
          return _buildSectionGroup(
              context,
              type: entry.key,
              options: entry.value
          );
        }).toList(),
      ),
    );
  }

  /// 构建单个分组（例如：语言组、时长组）
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
                  color: Colors.grey[800],
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
        Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 16, endIndent: 16),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建单个标签 UI (逻辑与之前的 AgeRatingSection 类似，但更通用)
  Widget _buildSingleTag(TagType type, FilterOptionItem option) {
    // 查找当前是否被选中
    final tagIndex = uiState.selected.indexWhere(
          (t) => t.type == type.stringValue && t.name == option.value,
    );
    final isSelected = tagIndex != -1;
    final isExclude = isSelected ? uiState.selected[tagIndex].isExclude : false;

    const errorColor = Color(0xFFFF4D4F);
    final activeColor = option.activeColor;

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
      onTap: () => notifier.toggleTag(type.stringValue, option.value, refreshData: false),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6), // 稍微圆一点
          border: border,
        ),
        child: Text(
          option.label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- 辅助方法：获取图标 ---
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

  // --- 辅助方法：获取标题 ---
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
// 模拟数据生成器 - 实际开发中请替换为你真实的 Enum 数据
List<FilterOptionItem> _getAgeOptions() {
  // 假设你原来的 AgeRatingEnum 转换过来
  return [
    SimpleFilterOption(label: "全年龄", value: "all", activeColor: Colors.green),
    SimpleFilterOption(label: "R18", value: "r18", activeColor: Colors.red),
  ];
}

List<FilterOptionItem> _getLangOptions() {
  return [
    SimpleFilterOption(label: "中文", value: "chinese", activeColor: Colors.blue),
    SimpleFilterOption(label: "日语", value: "japanese", activeColor: Colors.pinkAccent),
    SimpleFilterOption(label: "英语", value: "english", activeColor: Colors.indigo),
  ];
}

List<FilterOptionItem> _getDurationOptions() {
  // 这种一般是范围，value 可以传后端能识别的 key
  return [
    SimpleFilterOption(label: "短篇 (<10m)", value: "short", activeColor: Colors.teal),
    SimpleFilterOption(label: "中篇 (10-30m)", value: "medium", activeColor: Colors.teal),
    SimpleFilterOption(label: "长篇 (>30m)", value: "long", activeColor: Colors.teal),
  ];
}

List<FilterOptionItem> _getRateOptions() {
  return [
    SimpleFilterOption(label: "好评 (4★+)", value: "high_rate", activeColor: Colors.amber[800]!),
    SimpleFilterOption(label: "一般", value: "mid_rate", activeColor: Colors.amber),
  ];
}