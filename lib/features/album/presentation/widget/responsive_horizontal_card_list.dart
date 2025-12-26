import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/smart_color_card.dart';

class ResponsiveHorizontalCardList extends StatefulWidget {
  final List<Work> items;

  const ResponsiveHorizontalCardList({super.key, required this.items});

  @override
  State<ResponsiveHorizontalCardList> createState() =>
      _ResponsiveHorizontalCardListState();
}

class _ResponsiveHorizontalCardListState
    extends State<ResponsiveHorizontalCardList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);
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
      final cardHeight = cardWidth / (4 / 3) + 60;

      return SizedBox(
        height: cardHeight,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: isDesktop
              ? const BouncingScrollPhysics() // 桌面端拖拽平滑
              : const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: cardWidth,
              child: SmartColorCard(
                width: cardWidth,
                work: widget.items[index],
              ),
            );
          },
          separatorBuilder: (context, index) => SizedBox(width: spacing),
        ),
      );
    });
  }
}
