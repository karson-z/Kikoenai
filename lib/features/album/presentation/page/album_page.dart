import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_config.dart';
import 'package:name_app/config/work_layout_strategy.dart';
import 'package:name_app/core/widgets/layout/adaptive_app_bar_mobile.dart';
import 'package:name_app/features/album/data/model/product_mock.dart';
import 'package:name_app/features/album/presentation/widget/work_grid_layout.dart';

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
                  return MobileSearchAppBar(
                    collapsePercent: collapsePercent,
                    collapsePercentNotifier: collapsePercentNotifier,
                    filters: _filters,
                    selectedFilter: _selectedFilter,
                    onFilterChanged: _onFilterChanged,
                  );
                },
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
