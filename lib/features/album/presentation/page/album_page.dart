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
  final collapsePercentNotifier =
      ValueNotifier<double>(0.0); // 取代 _collapsePercent
  String _selectedFilter = '全部';
  final List<String> _filters = ['全部', '最新', '最热', '收藏最多'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    collapsePercentNotifier.dispose();
    super.dispose();
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
            if ((percent - collapsePercentNotifier.value).abs() > 0.01) {
              collapsePercentNotifier.value = percent; // 仅更新 ValueNotifier
            }
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            // 移动端搜索栏
            if (deviceType == DeviceType.mobile)
              ValueListenableBuilder<double>(
                valueListenable: collapsePercentNotifier,
                builder: (_, collapsePercent, __) {
                  return MobileSearchAppBar(collapsePercent: collapsePercent);
                },
              ),
            // TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: TabBarDelegateWrapper(
                collapsePercentNotifier: collapsePercentNotifier,
                selectedFilter: _selectedFilter,
                filters: _filters,
                onFilterChanged: _onFilterChanged,
              ),
            ),
            // 内容区
            ResponsiveCardGrid(
              products: _loading
                  ? List.generate(8, (_) => Product.empty())
                  : mockProducts,
            ),
          ],
        ),
      ),
    );
  }
}
