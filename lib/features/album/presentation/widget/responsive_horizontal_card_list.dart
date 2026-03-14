import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/smart_color_card.dart';

class ResponsiveHorizontalCardList extends StatelessWidget {
  final List<Work> items;

  const ResponsiveHorizontalCardList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // 判空保护，避免空数组导致的计算错误
    if (items.isEmpty) return const SizedBox();

    const layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);
    var columns = layoutStrategy.getColumnsCount(context);
    final spacing = layoutStrategy.getColumnSpacing(context) + 2;
    final deviceType = layoutStrategy.getDeviceType(context);

    if (deviceType != DeviceType.mobile) {
      columns += 2;
    }

    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux
    ].contains(Theme.of(context).platform);

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final totalSpacing = (columns - 1) * spacing;
      final cardWidth = (screenWidth - totalSpacing) / columns;
      // 高度计算保持不变
      final cardHeight = cardWidth / (4 / 3) + 60;

      return SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: isDesktop
              ? const BouncingScrollPhysics()
              : const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length, // 仅渲染真实数据长度
          itemBuilder: (context, index) {
            // --- 渲染正常卡片 ---
            return SizedBox(
              width: cardWidth,
              child: SmartColorCard(
                width: cardWidth,
                work: items[index],
              ),
            );
          },
          separatorBuilder: (context, index) => SizedBox(width: spacing),
        ),
      );
    });
  }
}