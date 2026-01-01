import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/smart_color_card.dart';

class ResponsiveHorizontalCardList extends StatefulWidget {
  final List<Work> items;
  // 新增参数
  final VoidCallback? onLoadMore;
  final bool hasMore;

  const ResponsiveHorizontalCardList({
    super.key,
    required this.items,
    this.onLoadMore,
    this.hasMore = false, // 默认为 false
  });

  @override
  State<ResponsiveHorizontalCardList> createState() =>
      _ResponsiveHorizontalCardListState();
}

class _ResponsiveHorizontalCardListState
    extends State<ResponsiveHorizontalCardList> {
  late final ScrollController _scrollController;
  bool _isLoading = false; // 加锁，防止重复触发

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

  // 监听组件更新，当数据变多时解锁 Loading 状态
  @override
  void didUpdateWidget(ResponsiveHorizontalCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length > oldWidget.items.length) {
      _isLoading = false;
    }
  }

  void _triggerLoadMore() {
    if (!_isLoading && widget.hasMore && widget.onLoadMore != null) {
      // 这里的 setState 不是必须的，因为 _isLoading 只是内部逻辑锁，
      // 但加上可以确保逻辑严谨，debug 时更清晰
      _isLoading = true;
      // 使用 postFrameCallback 避免构建期间 setState 报错
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLoadMore!();
      });
    }
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
      // 高度计算保持不变
      final cardHeight = cardWidth / (4 / 3) + 60;

      // 如果有更多，列表项总数 + 1
      final itemCount = widget.hasMore ? widget.items.length + 1 : widget.items.length;

      return SizedBox(
        height: cardHeight,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: isDesktop
              ? const BouncingScrollPhysics()
              : const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // --- 渲染 Loading 尾部 ---
            if (index == widget.items.length) {
              // 渲染到这里说明用户滑到了最后，触发加载
              _triggerLoadMore();

              return SizedBox(
                width: cardWidth, // 保持宽度一致，体验更好
                child: const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              );
            }

            // --- 渲染正常卡片 ---
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