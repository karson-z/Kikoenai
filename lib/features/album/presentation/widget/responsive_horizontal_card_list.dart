import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/core/enums/device_type.dart';
import 'package:name_app/features/album/data/model/work.dart';
import 'package:name_app/features/album/presentation/widget/smart_color_card.dart';

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
  bool _isSnapping = false;

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

  void _snapScroll(double cardWidth, double spacing) {
    if (!_scrollController.hasClients || _isSnapping) return;

    final scrollOffset = _scrollController.offset;
    final singleItemExtent = cardWidth + spacing;
    final targetIndex = (scrollOffset / singleItemExtent).round();
    final targetOffset = targetIndex * singleItemExtent;

    _isSnapping = true;
    _scrollController
        .animateTo(targetOffset,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
        .whenComplete(() => _isSnapping = false);
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
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (isDesktop) {
              _snapScroll(cardWidth, spacing);
            }
            return true;
          },
          child: ScrollConfiguration(
            behavior: _DesktopDragScrollBehavior(),
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
          ),
        ),
      );
    });
  }
}

/// 自定义桌面端拖拽平滑滚动，不显示滚动条
class _DesktopDragScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
