import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';

class LocalMediaPanel extends StatefulWidget {
  const LocalMediaPanel({super.key});

  @override
  State<LocalMediaPanel> createState() => _LocalMediaPanelState();
}

class _LocalMediaPanelState extends State<LocalMediaPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: NestedScrollView(
        // 1. 外层滚动视图：使用 SliverAppBar 重构头部
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 与背景色保持一致
              titleSpacing: 0,   // 取消默认间距，由内部 Padding 控制以对齐下方列表
              toolbarHeight: 64, // 给 _buildHeader 预留高度
              // 标题区域放置 _buildHeader
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildHeader(isDark),
              ),
              // Bottom 区域放置面包屑，使用 PreferredSize 指定高度
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(60), // 面包屑高度 + 底部间距
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: BreadcrumbBar(),
                ),
              ),
            ),
          ];
        },

        // 2. 内层视图（TabBarView 及其内部的滚动组件）
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              CustomScrollView(
                slivers: [
                  _buildPendingSliver(isDark),
                ],
              ),
              CustomScrollView(
                slivers: [
                  _buildParsedSliver(isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 顶部标题和导航
  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            "本地媒体",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: 150,
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "待解析"),
              Tab(text: "已解析"),
            ],
          ),
        ),
      ],
    );
  }

  // 面包屑导航
  Widget _buildBreadcrumbs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 18, color: Colors.grey[500]),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          const Text("主文件夹", style: TextStyle(fontSize: 13, color: Colors.blue)),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          const Text("当前目录", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 待解析列表视图
  Widget _buildPendingSliver(bool isDark) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          _buildListRow("2024_Q4_财务报告.pdf", "解析中", Colors.blue, isDark, isLoading: true),
          _buildListRow("用户调研汇总_v2.xlsx", "等待中", Colors.grey, isDark),
        ],
      ),
    );
  }

  Widget _buildListRow(String name, String status, Color color, bool isDark, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.description, color: isLoading ? Colors.blue : Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (isLoading) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                if (isLoading) const SizedBox(width: 6),
                Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }

  // 已解析网格视图
  Widget _buildParsedSliver(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16),
      sliver: SliverLayoutBuilder(
        builder: (BuildContext context, SliverConstraints constraints) {
          int crossAxisCount = constraints.crossAxisExtent > 900 ? 3 : (constraints.crossAxisExtent > 600 ? 2 : 1);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 220,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildParsedCard(isDark),
              childCount: 4,
            ),
          );
        },
      ),
    );
  }

  Widget _buildParsedCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.file_present, color: Colors.blue, size: 20),
              ),
              const Text("#8921", style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("2023年度市场分析报告.pdf", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const Text("COMPLETED 2H AGO", style: TextStyle(color: Colors.grey, fontSize: 10)),
          const Spacer(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("置信度", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("98.5%", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: 0.985, backgroundColor: Colors.grey[200], color: Colors.green, minHeight: 6),
        ],
      ),
    );
  }
}