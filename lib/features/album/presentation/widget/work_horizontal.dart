import 'package:flutter/material.dart';
import 'dart:math';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/widget/work_vertical_colum.dart';

class WorkListHorizontal extends StatefulWidget {
  final List<Work> items;
  final VoidCallback? onLoadMore; // 新增：加载更多回调
  final bool hasMore;             // 新增：是否有更多数据

  const WorkListHorizontal({
    super.key,
    required this.items,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<WorkListHorizontal> createState() => _WorkListHorizontalState();
}

class _WorkListHorizontalState extends State<WorkListHorizontal> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false; // 防止重复触发

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(WorkListHorizontal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 items 数量增加时，重置 loading 锁
    if (widget.items.length > oldWidget.items.length) {
      _isLoading = false;
    }
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

  void _checkLoadMore(int index, int totalDataPages) {
    // 触发策略：滑动到【数据页的最后一页】或者【Loading页】时触发
    // index 是当前页码（从0开始）
    // totalDataPages 是纯数据的总页数
    if (widget.hasMore && !_isLoading && widget.onLoadMore != null) {
      // 如果当前页是最后一页数据，或者已经滑到了 loading 页
      if (index >= totalDataPages - 1) {
        _isLoading = true; // 加锁
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;
    const cardHeight = 65.0;
    const maxCardsPerColumn = 3;

    // 1. 拆分成纵向组件，每列最多3个卡片
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
        final maxColumnsPerScreen = WorkListLayout(layoutType: WorkListLayoutType.list)
            .getColumnsCount(context);

        final visibleColumns = maxColumnsPerScreen;

        // 计算单列宽度
        final columnWidth =
            (availableWidth - (visibleColumns - 1) * spacing) / visibleColumns;
        final totalColumns = columnComponents.length;
        final int dataPagesCount = (totalColumns / visibleColumns).ceil();
        final int totalPageViewCount = widget.hasMore ? dataPagesCount + 1 : dataPagesCount;
        const pageHeight = cardHeight * maxCardsPerColumn + (maxCardsPerColumn - 1);

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPageViewCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _checkLoadMore(index, dataPagesCount);
                },
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, pageIndex) {
                  // --- 情况 A: 渲染 Loading 页 ---
                  // 如果当前索引 等于 数据总页数，说明这是多出来的那一页 Loading
                  if (widget.hasMore && pageIndex == dataPagesCount) {
                    return Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }

                  // --- 情况 B: 渲染数据页 ---
                  final startIndex = pageIndex * visibleColumns;
                  final endIndex = min(startIndex + visibleColumns, totalColumns);

                  // 安全检查：如果数据还没有加载完但计算有误，防止越界
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
                          SizedBox(width: spacing),
                      ],
                    ],
                  );
                },
              ),
            ),

            // 左右箭头 (Desktop)
            // 注意：totalPageViewCount 可能包含了 Loading 页，箭头逻辑需要适配
            if (isDesktop && totalPageViewCount > 1) ...[
              if (_currentPage > 0)
                Positioned(
                  left: 0,
                  child: IconButton(
                    onPressed: () => _changePage(-1),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Colors.black,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),

              if (_currentPage < totalPageViewCount - 1)
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