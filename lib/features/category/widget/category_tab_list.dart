import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/provider/work_layout_provider.dart';
import '../../../core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../album/widget/work_grid_layout.dart';
import '../../album/widget/work_list_layout.dart';
import '../provider/category_data_provider.dart';
import '../provider/category_keep_alive.dart';

class CategoryListTab extends ConsumerStatefulWidget {
  final SortOrder sortOrder;
  final double? pinnedHeaderHeight;
  final bool isFilterOpen;

  const CategoryListTab({
    Key? key,
    required this.sortOrder,
    this.pinnedHeaderHeight,
    required this.isFilterOpen,
  }) : super(key: key);

  @override
  ConsumerState<CategoryListTab> createState() => _CategoryListTabState();
}

class _CategoryListTabState extends ConsumerState<CategoryListTab>
    with AutomaticKeepAliveClientMixin { // 1. 保持 AutomaticKeepAliveClientMixin
  /// 列表顶部的零高度标记，用于定位当前 tab 自己的 Scrollable
  final GlobalKey _topMarkerKey = GlobalKey();

  /// 滚动超过该距离后才允许显示回到顶部按钮
  static const double _backToTopThreshold = 300;

  bool _showBackToTop = false;

  /// 内容向上走（往底部浏览）时隐藏按钮，内容向下走（往顶部回滚）时显示按钮；
  /// 已接近顶部时始终隐藏
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification is! ScrollUpdateNotification) {
      return false;
    }
    final delta = notification.scrollDelta ?? 0.0;
    if (delta > 0) {
      // 滚动位置增加：内容向上走，隐藏
      _updateBackToTop(false);
    } else if (delta < 0) {
      // 滚动位置减少：内容向下走，且离开顶部足够远才显示
      _updateBackToTop(
        notification.metrics.pixels > _backToTopThreshold,
      );
    }
    return false;
  }

  void _updateBackToTop(bool visible) {
    if (!mounted || _showBackToTop == visible) return;
    setState(() => _showBackToTop = visible);
  }

  void _scrollToTop() {
    _updateBackToTop(false);
    // 列表在 NestedScrollView 内部，不能直接挂 ScrollController，
    // 通过顶部标记找到当前列表自己的 Scrollable 再滚回顶部
    final markerContext = _topMarkerKey.currentContext;
    final scrollable =
        markerContext == null ? null : Scrollable.maybeOf(markerContext);
    scrollable?.position.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    // 首次加载时，立即将自己注册为活跃
    // 使用 microtask 避免在构建过程中修改 Provider
    Future.microtask(() {
      ref.read(keepAliveManagerProvider.notifier).markAsActive(widget.sortOrder);
    });
  }
  @override
  bool get wantKeepAlive {
    final activeList = ref.read(keepAliveManagerProvider);
    return activeList.contains(widget.sortOrder);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<List<SortOrder>>(keepAliveManagerProvider, (previous, next) {
      // 如果名单变了，检查由于 "我" 是否还应该活着
      // 这里的 updateKeepAlive 会触发 wantKeepAlive 的重新读取
      updateKeepAlive();
    });
    final manager = ref.read(keepAliveManagerProvider.notifier);
    // 只有当自己不是列表最后一个（最新的）时，才去刷新位置
    final list = ref.read(keepAliveManagerProvider);
    if (list.isEmpty || list.last != widget.sortOrder) {
      Future.microtask(() => manager.markAsActive(widget.sortOrder));
    }
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                edgeOffset: widget.pinnedHeaderHeight ?? 0,
                onRefresh: () async {
                  return ref.refresh(categoryProvider(widget.sortOrder).future);
                },
                child: CustomScrollView(
                  key: PageStorageKey<String>(widget.sortOrder.label),
                  physics: widget.isFilterOpen
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverOverlapInjector(
                      handle:
                          NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    ),
                    // 顶部标记：回到顶部时用于定位当前列表的 Scrollable
                    SliverToBoxAdapter(
                      child: SizedBox.shrink(key: _topMarkerKey),
                    ),
                    ..._buildCommonContent(ref),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              ),
            ),
            _buildBackToTopButton(context),
          ],
        ),
      ),
    );
  }

  /// 底部悬浮的“回到顶部”按钮：往下滚动时出现，往上滚动时消失
  Widget _buildBackToTopButton(BuildContext context) {
    // 筛选抽屉展开时隐藏，避免被遮挡误触
    if (widget.isFilterOpen) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      right: 16,
      bottom: 24,
      child: IgnorePointer(
        ignoring: !_showBackToTop,
        child: AnimatedOpacity(
          opacity: _showBackToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: _showBackToTop ? Offset.zero : const Offset(0, 0.6),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: FloatingActionButton.small(
              heroTag: 'back_to_top_${widget.sortOrder.name}',
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black54,
              elevation: 3,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCommonContent(
      WidgetRef ref) {
    final categoryWorks = ref.watch(categoryProvider(widget.sortOrder));
    final categoryController = ref.read(categoryProvider(widget.sortOrder).notifier);
    return [
      categoryWorks.when(
        skipLoadingOnRefresh: true,

        data: (data) {
          // 网格 / 列表模式（全局共享 + 持久化）
          final isListMode =
              ref.watch(workLayoutModeProvider) == WorkLayoutMode.list;
          if (isListMode) {
            return ResponsiveWorkList(
              pagingState: data,
              emptyMessage: '暂无数据',
              fetchNextPage: () {
                categoryController.fetchNextPage();
              },
            );
          }
          return ResponsiveCardGrid(
            pagingState: data,
            emptyMessage: '暂无数据',
            fetchNextPage: () {
              categoryController.fetchNextPage();
            },
          );
        },

        loading: () => const SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: Center(
              child: LottieLoadingIndicator(
                size: 76,
                message: '加载中...',
              ),
            ),
          ),
        ),

        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: Center(
              child: TextButton(
                onPressed: () => ref.refresh(categoryProvider(widget.sortOrder)),
                child: Text('加载失败: $e\n点击重试', textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
