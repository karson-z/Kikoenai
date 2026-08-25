import 'package:flutter/material.dart';
import 'dart:math';
import 'package:kikoenai/config/work_layout_config.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/features/album/widget/work_vertical_colum.dart';

class WorkListHorizontal extends StatefulWidget {
  final List<Work> items;

  const WorkListHorizontal({
    super.key,
    required this.items,
  });

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
    // 如果没有数据，直接返回空盒子，避免后续计算报错
    if (widget.items.isEmpty) return const SizedBox();

    const spacing = 16.0;
    const cardHeight = 65.0;
    const maxCardsPerColumn = 3;

    // 1. 拆分成纵向组件，每列最多3个卡片
    final List<List<Work>> columnComponents = [];
    for (var i = 0; i < widget.items.length; i += maxCardsPerColumn) {
      columnComponents.add(widget.items.sublist(
        i,
        min(i + maxCardsPerColumn, widget.items.length),
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
        final visibleColumns = WorkLayoutConfig.list(context).columns;

        // 计算单列宽度
        final columnWidth =
            (availableWidth - (visibleColumns - 1) * spacing) / visibleColumns;
        final totalColumns = columnComponents.length;
        // 计算纯数据总页数
        final int totalPageViewCount = (totalColumns / visibleColumns).ceil();
        const pageHeight = cardHeight * maxCardsPerColumn + (maxCardsPerColumn - 1);

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPageViewCount,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  // --- 渲染数据页 ---
                  final startIndex = pageIndex * visibleColumns;
                  final endIndex = min(startIndex + visibleColumns, totalColumns);

                  // 安全检查：防止越界
                  if (startIndex >= totalColumns) return const SizedBox();

                  final pageColumns = columnComponents.sublist(startIndex, endIndex);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                        if (i < pageColumns.length - 1)
                          const SizedBox(width: spacing),
                      ],
                    ],
                  );
                },
              ),
            ),

            // 左右箭头 (Desktop)
            if (isDesktop && totalPageViewCount > 1) ...[
              if (_currentPage > 0)
                Positioned(
                  left: 0,
                  child: IconButton(
                    onPressed: () => _changePage(-1),
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    color: Colors.black87,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      elevation: 2,
                    ),
                  ),
                ),

              if (_currentPage < totalPageViewCount - 1)
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () => _changePage(1),
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    color: Colors.black87,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      elevation: 2,
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
