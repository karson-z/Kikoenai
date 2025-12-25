import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/device_type.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../../../../../core/enums/age_rating.dart';
import '../../../../../../../core/enums/sort_options.dart';
import '../../../../../../../core/widgets/common/collapsible_tab_bar.dart';
import '../../../../../../../core/widgets/layout/adaptive_app_bar_mobile.dart';
import '../../../album/presentation/widget/skeleton/skeleton_grid.dart';
import '../../../album/presentation/widget/work_grid_layout.dart';
import '../../widget/filter_header_delegate.dart';
import '../viewmodel/provider/category_data_provider.dart';
import '../viewmodel/provider/category_option_provider.dart';
import '../viewmodel/state/category_ui_state.dart';


class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage>
    with SingleTickerProviderStateMixin {

  final List<SortOrder> sortOrders = SortOrder.values;
  late AutoScrollController _autoScrollController;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final double pinnedHeaderHeight = 90.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: sortOrders.length, vsync: this);
    _autoScrollController = AutoScrollController(
      axis: Axis.horizontal,
    );
    // 监听 Tab 切换，同步排序状态给 Provider
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final order = sortOrders[_tabController.index];
        ref.read(categoryUiProvider.notifier).setSort(sortOption: order, refreshData: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _autoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局状态
    final uiState = ref.watch(categoryUiProvider);
    final uiNotifier = ref.read(categoryUiProvider.notifier);
    final worksAsync = ref.watch(categoryProvider);
    final categoryController = ref.read(categoryProvider.notifier);
    final totalCount = worksAsync.value?.totalCount ?? 0;
    final isMobile = context.isMobile;
    // 主题逻辑 (纯黑/纯白)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black45;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final Color dividerColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    ref.listen<CategoryUiState>(categoryUiProvider, (previous, next) {
      // 如果列表变长了 (新增了 Tag)
      if (previous != null && next.selected.length > previous.selected.length) {

        // 滚动到最后一个索引
        final targetIndex = next.selected.length - 1;

        // 使用 scroll_to_index 的方法
        _autoScrollController.scrollToIndex(
          targetIndex,
          preferPosition: AutoScrollPosition.end, // 【关键】尽量让该元素靠在可视区域末尾(最右侧)
          duration: const Duration(milliseconds: 300),
        );
      }
    });
    // 同步搜索框内容 (如果切换 Tab 清空了 State，这里也要清空输入框)
    if (uiState.localSearchKeyword.isEmpty && _searchController.text.isNotEmpty) {
      //为了防止构建期间修改状态报错，用 addPostFrameCallback，或者在这里直接 clear 因为 build 不受影响
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) _searchController.clear();
      });
    }

    return SafeArea(child: Scaffold(
      backgroundColor: bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // 1. 搜索栏 (Floating)
          if(isMobile)
          SliverAppBar(
            expandedHeight: 80,
            // 核心修复：面板打开时禁止悬浮，防止遮挡
            floating: !uiState.isFilterOpen,
            snap: !uiState.isFilterOpen,

            backgroundColor: bgColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: MobileSearchAppBar(),
            ),
          ),

          // 2. 排序与筛选栏 (Pinned)
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverPersistentHeader(
              pinned: true,
              delegate: FilterHeaderDelegate(
                ref: ref,
                tabController: _tabController,
                pinnedHeight: pinnedHeaderHeight, // 使用更紧凑的高度
                sortOrders: sortOrders,
                uiState: uiState,
                uiNotifier: uiNotifier,
                totalCount: totalCount,
                scrollController: _autoScrollController,
                buildFilterRow: _buildFilterRowContent, // 将你的构建函数传进去
              ),
            ),
          ),
        ],

        // 3. Body (Stack 实现筛选面板覆盖)
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: sortOrders.map((sortOrder) {
                // 使用 Builder 获取正确的 context (用于 Injector)
                return Builder(builder: (context) {
                  return CustomScrollView(
                    // 必须加上 key，保证每个 Tab 滚动状态独立
                    key: PageStorageKey<String>(sortOrder.label),
                    // 核心修复：面板打开时禁止底层滚动
                    physics: uiState.isFilterOpen
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),

                    slivers: [
                      // 1. 注入器：防止内容被吸顶 Header 遮挡
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      ),

                      // 2. 列表内容
                      ..._buildCommonContent(worksAsync, categoryController),

                      // 3. 底部留白
                      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                    ],
                  );
                });
              }).toList(),
            ),

            // 遮罩层
            if (uiState.isFilterOpen)
              Positioned.fill(
                top: pinnedHeaderHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque, // 拦截点击
                  onTap: () => uiNotifier.toggleFilterDrawer(),
                  child: Container(color: Colors.black54),
                ),
              ),

            // 筛选面板 (动画)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: pinnedHeaderHeight,
              left: 0,
              right: 0,
              child: _buildFilterDrawer(
                  uiState, uiNotifier,
                  bgColor, textColor, subTextColor, fillColor, dividerColor, primaryColor,
                  _searchController // 传入控制器
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // --- 内容构建逻辑 ---

  List<Widget> _buildCommonContent(AsyncValue worksAsync, CategoryDataNotifier controller) {
    return [
      worksAsync.when(
        data: (data) => ResponsiveCardGrid(
          work: data.works,
          hasMore: data.hasMore,
          onLoadMore: () {
            controller.loadMore();
          },
        ),
        // 加载中
        loading: () => const ResponsiveCardGridSkeleton(),
        // 错误
        error: (e, _) => SliverToBoxAdapter(
          child: SizedBox(
              height: 120,
              child: Center(child: Text('加载失败: $e', style: const TextStyle(color: Colors.red)))
          ),
        ),
      ),
    ];
  }


  Widget _buildFilterRowContent(
      CategoryUiState uiState, CategoryUiNotifier notifier, int totalCount,
      Color bgColor, Color textColor, Color subTextColor, Color fillColor, Color primaryColor,
      AutoScrollController scrollController
      ) {

    // 定义高度常量，方便统一调整
    const double rowHeight = 40.0;
    // 定义为了显示角标而需要的顶部偏移量
    const double badgeSpaceOffset = 6.0;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(left: 16, right: 0),
      alignment: Alignment.centerLeft,
      child: Row(
        // 使用 CrossAxisAlignment.start 让大家以顶部为基准对齐
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --- 1. 筛选按钮 (保持不变) ---
          Padding(
            padding: const EdgeInsets.only(top: badgeSpaceOffset + 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: () => notifier.toggleFilterDrawer(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: uiState.isFilterOpen ? primaryColor.withOpacity(0.1) : fillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(uiState.isFilterOpen ? Icons.keyboard_arrow_up : Icons.tune, size: 16, color: uiState.isFilterOpen ? primaryColor : textColor),
                        const SizedBox(width: 4),
                        Text(uiState.isFilterOpen ? "收起" : "筛选", style: TextStyle(color: uiState.isFilterOpen ? primaryColor : textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                if (uiState.selected.isNotEmpty && !uiState.isFilterOpen)
                  Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: bgColor, width: 1.5)), child: Text("${uiState.selected.length}", style: const TextStyle(color: Colors.white, fontSize: 9))))
              ],
            ),
          ),

          const SizedBox(width: 12),

          // --- 2. 选中的 Tag 列表 (【核心修改区域】) ---
          Expanded(
            // 【关键点】使用 ShaderMask 包裹 ListView 的容器
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                // 创建一个从左到右的线性渐变
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  // 颜色数组：前面是白色（代表不透明），最后是透明色
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  // 颜色分布点：0%~85% 是纯白（完全显示），85%~100% 渐变到透明（淡出）
                  stops: [0.0, 0.85, 1.0],
                ).createShader(bounds);
              },
              // 【关键混合模式】使用 dstIn，根据 shader 的 alpha 值来决定子组件的显示
              blendMode: BlendMode.dstIn,

              child: SizedBox(
                height: rowHeight,
                child: ListView.builder(
                  // 保持裁剪，防止内容溢出边界
                  clipBehavior: Clip.hardEdge,

                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: uiState.selected.length,

                  // 顶部留出空间给角标
                  padding: const EdgeInsets.fromLTRB(0, 8, 4, 4),

                  itemBuilder: (context, index) {
                    final tag = uiState.selected[index];
                    final color = tag.isExclude ? const Color(0xFFFF4D4F) : primaryColor;

                    return AutoScrollTag(
                      key: ValueKey(index),
                      controller: scrollController,
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          clipBehavior: Clip.none, // 允许角标悬浮
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: color, width: 1),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                            ),
                            // 删除按钮
                            Positioned(
                              top: -6, right: -6,
                              child: GestureDetector(
                                onTap: () => notifier.removeTag(tag.type, tag.name, refreshData: true),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bgColor, width: 1),
                                  ),
                                  child: const Icon(Icons.close, size: 10, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // --- 3. 总数统计 (保持不变) ---
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4, top: badgeSpaceOffset + 6),
            child: Text("共 $totalCount 条", style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // --- 筛选抽屉 UI ---

  Widget _buildFilterDrawer(
      CategoryUiState uiState, CategoryUiNotifier notifier,
      Color bgColor, Color textColor, Color subTextColor, Color fillColor, Color dividerColor, Color primaryColor,
      TextEditingController searchController // 接收控制器
      ) {
    // 定义筛选分类
    final categories = ["标签", "社团", "声优", "年龄分级"];

    return Material(
      color: bgColor,
      elevation: 4,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: uiState.isFilterOpen ? null : 0, // 使用 State
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 260,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧导航
                    Container(
                      width: 90,
                      color: fillColor,
                      child: ListView.builder(
                        primary: false,
                        padding: EdgeInsets.zero,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = uiState.selectedFilterIndex == index;
                          return GestureDetector(
                            onTap: () => notifier.setFilterIndex(index), // 使用 Notifier
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? bgColor : Colors.transparent,
                                border: isSelected
                                    ? Border(left: BorderSide(color: primaryColor, width: 3))
                                    : null,
                              ),
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: isSelected ? primaryColor : subTextColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 右侧内容
                    Expanded(
                      child: Container(
                        color: bgColor,
                        child: Column(
                          children: [
                            // 搜索框 (分级页不显示)
                            if (uiState.selectedFilterIndex != 3)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    controller: searchController,
                                    onChanged: (val) => notifier.setLocalSearchKeyword(val),
                                    style: TextStyle(fontSize: 13, color: textColor),
                                    decoration: InputDecoration(
                                      hintText: "搜索...",
                                      hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                                      prefixIcon: Icon(Icons.search, size: 18, color: subTextColor),
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor: fillColor,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                      suffixIcon: uiState.localSearchKeyword.isNotEmpty
                                          ? GestureDetector(
                                        onTap: () {
                                          notifier.setLocalSearchKeyword("");
                                          searchController.clear();
                                        },
                                        child: Icon(Icons.cancel, size: 16, color: subTextColor),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),

                            // 动态内容区 (Tag/Circle/VA/Age)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _buildRightContent(
                                  ref: ref,
                                  index: uiState.selectedFilterIndex,
                                  uiState: uiState,
                                  notifier: notifier,
                                  fillColor: fillColor,
                                  textColor: textColor,
                                  primaryColor: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 底部按钮
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(top: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => notifier.resetSelected(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subTextColor,
                          side: BorderSide(color: dividerColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("重置"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          notifier.toggleFilterDrawer();
                          ref.read(categoryProvider.notifier).refresh();
                          notifier.setLocalSearchKeyword("");
                          searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("完成"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 右侧内容分配逻辑 ---

  Widget _buildRightContent({
    required WidgetRef ref,
    required int index,
    required CategoryUiState uiState,
    required CategoryUiNotifier notifier,
    required Color fillColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    // 使用 TagType 枚举映射字符串
    switch (index) {
      case 0: // 标签
        final tagsAsync = ref.watch(tagsProvider);
        return _buildAsyncChipGrid<dynamic>(
          asyncValue: tagsAsync,
          uiState: uiState,
          type: "tag", // 根据你实际后端的 type 字符串调整
          notifier: notifier,
          labelBuilder: (item) => item.name ?? "",
          fillColor: fillColor, textColor: textColor, primaryColor: primaryColor,
        );
      case 1: // 社团
        final circlesAsync = ref.watch(circlesProvider);
        return _buildAsyncChipGrid<dynamic>(
          asyncValue: circlesAsync,
          uiState: uiState,
          type: "circle", // 根据你实际后端的 type 字符串调整
          notifier: notifier,
          labelBuilder: (item) => item.name ?? "",
          fillColor: fillColor, textColor: textColor, primaryColor: primaryColor,
        );
      case 2: // 声优
        final vasAsync = ref.watch(vasProvider);
        return _buildAsyncChipGrid<dynamic>(
          asyncValue: vasAsync,
          uiState: uiState,
          type: "va", // 根据你实际后端的 type 字符串调整 (例如 "artist" 或 "va")
          notifier: notifier,
          labelBuilder: (item) => item.name ?? "",
          fillColor: fillColor, textColor: textColor, primaryColor: primaryColor,
        );
      case 3: // 年龄分级
        return SingleChildScrollView(
          primary: false,
          child: _buildAgeRatingSection(uiState, notifier, fillColor, textColor, primaryColor),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildAsyncChipGrid<T>({
    required AsyncValue<List<T>> asyncValue,
    required CategoryUiState uiState,
    required String type,
    required CategoryUiNotifier notifier,
    required String Function(T) labelBuilder,
    required Color fillColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    return asyncValue.when(
      data: (originalList) {
        // 前端搜索过滤
        final list = originalList.where((item) {
          if (uiState.localSearchKeyword.isEmpty) return true; // 使用 State
          final name = labelBuilder(item);
          return name.toLowerCase().contains(uiState.localSearchKeyword.toLowerCase());
        }).toList();

        if (list.isEmpty) {
          return Center(child: Text(uiState.localSearchKeyword.isNotEmpty ? "未找到相关结果" : "暂无选项", style: TextStyle(color: textColor.withOpacity(0.5))));
        }

        return GridView.builder(
          primary: false, // 禁止占用主 ScrollController
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisExtent: 36,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = list[index];
            final name = labelBuilder(item);

            // 检查选中状态和是否排除
            final tagIndex = uiState.selected.indexWhere((t) => t.type == type && t.name == name);
            final isSelected = tagIndex != -1;
            final isExclude = isSelected ? uiState.selected[tagIndex].isExclude : false;

            return _buildGridChip(
              label: name,
              isSelected: isSelected,
              isExclude: isExclude,
              onTap: () => notifier.toggleTag(type, name, refreshData: false),
              fillColor: fillColor, textColor: textColor, primaryColor: primaryColor,
            );
          },
        );
      },
      error: (err, stack) => const Center(child: Text("加载失败", style: TextStyle(color: Colors.red))),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  // --- 基础 Chip 样式 (支持三态颜色) ---

  Widget _buildGridChip({
    required String label,
    required bool isSelected,
    required bool isExclude,
    required VoidCallback onTap,
    required Color fillColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    Color backgroundColor;
    Color labelColor;
    Border? border;
    const errorColor = Color(0xFFFF4D4F);

    if (!isSelected) {
      backgroundColor = fillColor;
      labelColor = textColor;
      border = null;
    } else if (isExclude) {
      backgroundColor = errorColor.withOpacity(0.1);
      labelColor = errorColor;
      border = Border.all(color: errorColor);
    } else {
      backgroundColor = primaryColor.withOpacity(0.1);
      labelColor = primaryColor;
      border = Border.all(color: primaryColor);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- 分级 UI ---

  Widget _buildAgeRatingSection(
      CategoryUiState uiState, CategoryUiNotifier notifier,
      Color fillColor, Color textColor, Color primaryColor
      ) {
    const ratings = AgeRatingEnum.values;
    const errorColor = Color(0xFFFF4D4F);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ratings.map((rating) {
        final tagIndex = uiState.selected.indexWhere(
              (t) => t.type == "age_rating" && t.name == rating.value,
        );
        final isSelected = tagIndex != -1;
        final isExclude = isSelected ? uiState.selected[tagIndex].isExclude : false;

        Color backgroundColor;
        Color labelColor;
        Border? border;
        final ratingColor = AgeRatingEnum.ageRatingColor(rating);

        if (!isSelected) {
          backgroundColor = fillColor;
          labelColor = textColor;
          border = Border.all(color: Colors.transparent);
        } else if (isExclude) {
          backgroundColor = errorColor.withOpacity(0.1);
          labelColor = errorColor;
          border = Border.all(color: errorColor);
        } else {
          backgroundColor = ratingColor.withOpacity(0.1);
          labelColor = ratingColor;
          border = Border.all(color: ratingColor);
        }

        return InkWell(
          onTap: () => notifier.toggleTag("age_rating", rating.value, refreshData: false),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: border,
            ),
            child: Text(
              rating.label,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}