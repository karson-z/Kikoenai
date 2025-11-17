import 'package:flutter/material.dart';

class CollapsibleTabBar extends StatefulWidget {
  final ValueNotifier<double> collapsePercentNotifier;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  const CollapsibleTabBar({
    Key? key,
    required this.collapsePercentNotifier,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<CollapsibleTabBar> createState() => _CollapsibleTabBarState();
}

class _CollapsibleTabBarState extends State<CollapsibleTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();

    final initialIndex =
    widget.filters.indexOf(widget.selectedFilter).clamp(0, widget.filters.length - 1);

    _controller = TabController(
      length: widget.filters.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _controller.addListener(() {
      if (_controller.indexIsChanging) {
        final filter = widget.filters[_controller.index];
        widget.onFilterChanged(filter);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CollapsibleTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果 selectedFilter 改变，需要同步 tabController.index
    final newIndex =
    widget.filters.indexOf(widget.selectedFilter).clamp(0, widget.filters.length - 1);
    if (newIndex != _controller.index) {
      _controller.index = newIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final theme = Theme.of(context);

    return Container(
      color: scaffoldBg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // TabBar
          Expanded(
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              padding: EdgeInsets.zero,
              indicatorPadding: EdgeInsets.zero,
              tabAlignment: TabAlignment.start,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 2.5,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 15),
              tabs: widget.filters
                  .map((f) => Tab(
                text: f,
              ))
                  .toList(),
            ),
          ),

          // 折叠后出现的搜索图标
          AnimatedBuilder(
            animation: widget.collapsePercentNotifier,
            builder: (_, __) {
              final collapsePercent = widget.collapsePercentNotifier.value;

              if (collapsePercent == 0) return const SizedBox.shrink();

              final opacity = collapsePercent.clamp(0.0, 1.0);
              final offsetX = (1 - opacity) * 0.3;

              return Transform.translate(
                offset: Offset(offsetX * 48, 0),
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
