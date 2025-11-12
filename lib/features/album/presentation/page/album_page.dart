import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_config.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/core/widgets/layout/adaptive_app_bar_mobile.dart';
import 'package:name_app/features/album/data/model/product_mock.dart';
import 'package:name_app/features/album/presentation/widget/work_grid_layout.dart';
import 'package:name_app/features/album/presentation/widget/work_tab_bar.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({Key? key}) : super(key: key);

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  bool _loading = true;
  double _collapsePercent = 0.0; // 0 -> 完全展开, 1 -> 完全折叠
  String _selectedFilter = '全部';

  final List<String> _filters = ['全部', '最新', '最热', '收藏最多'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  void _onFilterChanged(String newFilter) {
    if (newFilter == _selectedFilter) return;
    setState(() {
      _selectedFilter = newFilter;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = WorkLayoutStrategy().getDeviceType(context);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.axis == Axis.vertical) {
            final double offset = scroll.metrics.pixels.clamp(0, 80);
            final double percent = (offset / 80).clamp(0.0, 1.0);
            if ((percent - _collapsePercent).abs() > 0.01) {
              setState(() => _collapsePercent = percent);
            }
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            // 上方搜索栏
            if (deviceType == DeviceType.mobile)
              MobileSearchAppBar(collapsePercent: _collapsePercent),
            // TabBar + 搜索图标
            SliverPersistentHeader(
              pinned: true,
              delegate: TabBarDelegateWrapper(
                collapsePercent: _collapsePercent,
                selectedFilter: _selectedFilter,
                filters: _filters,
                onFilterChanged: _onFilterChanged,
              ),
            ),
            ResponsiveCardGrid(
              products: _loading
                  ? List.generate(8, (index) => Product.empty())
                  : mockProducts,
            ),
            // 内容区
          ],
        ),
      ),
    );
  }
}
