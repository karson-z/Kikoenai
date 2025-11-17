import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/features/album/data/model/work.dart';
import 'package:name_app/features/album/presentation/widget/work_vertical_colum.dart';


class WorkListHorizontal extends StatefulWidget {
  final List<Work> items;

  const WorkListHorizontal({super.key, required this.items});

  @override
  State<WorkListHorizontal> createState() => _WorkListHorizontalState();
}

class _WorkListHorizontalState extends State<WorkListHorizontal> {
  late final ScrollController _scrollController;
  int _currentIndex = 0;

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

  void _scrollToIndex(int index, double columnWidth, double spacing) {
    final offset = index * (columnWidth + spacing);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    const cardHeight = 75.0;
    const maxCardsPerColumn = 3;

    // 拆分成纵向组件，每列最多3个卡片
    final columnComponents = [];
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

        // 当前屏幕可显示列数
        final visibleColumns = columnComponents.length < maxColumnsPerScreen
            ? columnComponents.length
            : maxColumnsPerScreen;

        final columnWidth =
            (availableWidth - (visibleColumns - 1) * spacing) / visibleColumns;

        final totalColumns = columnComponents.length;

        final canScroll = totalColumns > visibleColumns;

        const pageHeight = cardHeight * maxCardsPerColumn + (maxCardsPerColumn - 1) * spacing;

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: pageHeight,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: canScroll ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: totalColumns,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: columnWidth,
                    child: VerticalCardColumn(
                      items: columnComponents[index],
                      width: columnWidth,
                      cardHeight: cardHeight,
                      maxHeight: pageHeight,
                    ),
                  );
                },
                separatorBuilder: (_, __) => SizedBox(width: spacing),
              ),
            ),

            // 左右箭头
            if (isDesktop) ...[
              Positioned(
                left: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: _currentIndex > 0 ? Colors.black : Colors.grey,
                  ),
                  onPressed: _currentIndex > 0
                      ? () => _scrollToIndex(_currentIndex - 1, columnWidth, spacing)
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: _currentIndex + visibleColumns < totalColumns ? Colors.black : Colors.grey,
                  ),
                  onPressed: _currentIndex + visibleColumns < totalColumns
                      ? () => _scrollToIndex(_currentIndex + 1, columnWidth, spacing)
                      : null,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
