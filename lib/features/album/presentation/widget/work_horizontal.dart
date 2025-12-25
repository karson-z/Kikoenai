import 'package:flutter/material.dart';
import 'dart:math'; // 需要引入 min
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/widget/work_vertical_colum.dart';

class WorkListHorizontal extends StatefulWidget {
  final List<Work> items;

  const WorkListHorizontal({super.key, required this.items});

  @override
  State<WorkListHorizontal> createState() => _WorkListHorizontalState();
}

class _WorkListHorizontalState extends State<WorkListHorizontal> {
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

  void _changePage(int increment) {
    _pageController.animateToPage(
      _currentPage + increment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const spacing =16.0;
    const cardHeight = 65.0;
    const maxCardsPerColumn = 3;

    // 1. 拆分成纵向组件，每列最多3个卡片 (保持原有逻辑)
    final List<List<Work>> columnComponents = [];
    for (var i = 0; i < widget.items.length; i += maxCardsPerColumn) {
      columnComponents.add(widget.items.sublist(
        i,
        (i + maxCardsPerColumn).clamp(0, widget.items.length),
      ));
    }

    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ].contains(Theme.of(context).platform);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // 获取当前屏幕配置允许显示的列数
        final maxColumnsPerScreen = WorkListLayout(layoutType: WorkListLayoutType.list)
            .getColumnsCount(context);

        final visibleColumns = maxColumnsPerScreen;

        // 计算单列宽度
        final columnWidth =
            (availableWidth - (visibleColumns - 1) * spacing) / visibleColumns;

        // 2. 将列再次拆分，计算总页数
        final totalColumns = columnComponents.length;
        final totalPages = (totalColumns / visibleColumns).ceil();

        // 计算整个区域的高度
        const pageHeight = cardHeight * maxCardsPerColumn + (maxCardsPerColumn - 1);

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, pageIndex) {
                  // 计算当前页包含哪几列
                  final startIndex = pageIndex * visibleColumns;
                  final endIndex = min(startIndex + visibleColumns, totalColumns);
                  final pageColumns = columnComponents.sublist(startIndex, endIndex);

                  // 构建当前页的布局 (Row)
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start, // 最后一页靠左对齐
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < pageColumns.length; i++) ...[
                        SizedBox(
                          width: columnWidth,
                          child: VerticalCardColumn(
                            items: pageColumns[i],
                            width: columnWidth,
                            cardHeight: cardHeight,
                            maxHeight: pageHeight,
                          ),
                        ),
                        // 只有不是当前页最后一列时才加间距，且不能超出 visibleColumns
                        if (i < pageColumns.length - 1)
                          SizedBox(width: spacing),
                      ],
                    ],
                  );
                },
              ),
            ),

            // 左右箭头 (仅在 Desktop 显示)
            if (isDesktop && totalPages > 1) ...[
              // 左箭头
              if (_currentPage > 0)
                Positioned(
                  left: 0,
                  child: IconButton(
                    onPressed: () => _changePage(-1),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Colors.black, // 或者根据主题设置颜色
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.7), // 增加背景以便在内容上可见
                    ),
                  ),
                ),

              // 右箭头
              if (_currentPage < totalPages - 1)
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () => _changePage(1),
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: Colors.black,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}