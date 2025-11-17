import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/features/album/presentation/widget/smart_color_card.dart';

class ResponsiveHorizontalCardList extends StatefulWidget {
  final List<Map<String, String>> items;

  const ResponsiveHorizontalCardList({super.key, required this.items});

  @override
  State<ResponsiveHorizontalCardList> createState() =>
      _ResponsiveHorizontalCardListState();
}

class _ResponsiveHorizontalCardListState
    extends State<ResponsiveHorizontalCardList> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToPage(int index) {
    if (index >= 0 && index < pages.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = index);
    }
  }

  late List<List<Map<String, String>>> pages = [];

  @override
  Widget build(BuildContext context) {
    // 判断是否桌面端
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux
    ].contains(Theme.of(context).platform);

    // 布局策略
    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);
    final columns = layoutStrategy.getColumnsCount(context);
    final spacing = layoutStrategy.getColumnSpacing(context);

    // 按页划分数据
    pages = [];
    for (var i = 0; i < widget.items.length; i += columns) {
      pages.add(widget.items.sublist(
        i,
        (i + columns).clamp(0, widget.items.length),
      ));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final totalSpacing = (columns - 1) * spacing;
      final cardWidth = (screenWidth - totalSpacing) / columns;
      final cardHeight = cardWidth / (4 / 3) + 60;

      Widget content;

      if (isDesktop) {
        // 桌面端：PageView + 左右箭头
        content = Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, pageIndex) {
                  final pageItems = pages[pageIndex];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for (var i = 0; i < pageItems.length; i++) ...[
                        SizedBox(
                          width: cardWidth,
                          child: SmartColorCard(
                            width: cardWidth,
                            imageUrl: pageItems[i]['image']!,
                            title: pageItems[i]['title']!,
                          ),
                        ),
                        if (i < pageItems.length - 1) SizedBox(width: spacing),
                      ],
                    ],
                  );
                },
              ),
            ),
            // 左右箭头
            Positioned(
              left: 0,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: _currentPage > 0 ? Colors.black : Colors.grey,
                ),
                onPressed:
                _currentPage > 0 ? () => _scrollToPage(_currentPage - 1) : null,
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: _currentPage < pages.length - 1 ? Colors.black : Colors.grey,
                ),
                onPressed: _currentPage < pages.length - 1
                    ? () => _scrollToPage(_currentPage + 1)
                    : null,
              ),
            ),
          ],
        );
      } else {
        // 移动端：自由滚动 ListView
        final itemsWithSpacing = <Widget>[];
        for (var i = 0; i < widget.items.length; i++) {
          itemsWithSpacing.add(
            SizedBox(
              width: cardWidth,
              child: SmartColorCard(
                width: cardWidth,
                imageUrl: widget.items[i]['image']!,
                title: widget.items[i]['title']!,
              ),
            ),
          );
          if (i != widget.items.length - 1) {
            itemsWithSpacing.add(SizedBox(width: spacing));
          }
        }

        content = SizedBox(
          height: cardHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: itemsWithSpacing,
          ),
        );
      }

      return content;
    });
  }
}
