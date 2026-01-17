import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// 引入你项目中的 Provider 和 Widget
import '../../../category/presentation/viewmodel/provider/category_option_provider.dart';
import '../../../category/widget/filter_drawer_panel.dart';
import '../../../category/widget/filter_row_panel.dart';
import '../../../category/widget/special_search.dart';
import '../../../settings/presentation/provider/setting_provider.dart';
import '../provider/playlist_filter_provider.dart';
import '../provider/playlist_provider.dart';
import '../widget/playlist_card_grid_view.dart';
import '../widget/playlist_sheet.dart';


class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({super.key});

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  // 筛选行的滚动控制器
  late AutoScrollController _autoScrollController;

  // AppBar 搜索框控制器
  final TextEditingController _appBarSearchController = TextEditingController();

  // 控制 AppBar 是否显示搜索输入框 (仅 UI 表现，数据在 Provider 中)
  bool _isAppBarSearching = false;

  @override
  void initState() {
    super.initState();
    _autoScrollController = AutoScrollController(axis: Axis.horizontal);
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _appBarSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取当前目标歌单
    final targetPlaylist = ref.watch(defaultMarkTargetPlaylistProvider);

    if (targetPlaylist == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(defaultMarkTargetPlaylistProvider.notifier).fetchAndCacheDefault();
      });
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final uiState = ref.watch(playlistUiProvider);
    final uiNotifier = ref.read(playlistUiProvider.notifier);

    // 检查 ID 是否同步，不同步则更新
    if (uiState.request.id != targetPlaylist.id) {
      // 使用 microtask 避免构建时 setState
      Future.microtask(() => uiNotifier.initId(targetPlaylist.id));
    }

    final worksAsync = ref.watch(playlistWorksProvider(targetPlaylist.id));

    // 同步 AppBar 搜索框文字 (当外部重置搜索时)
    if (uiState.request.textKeyword.isEmpty && _appBarSearchController.text.isNotEmpty) {
      // 避免死循环
      if (_appBarSearchController.text != "") {
        _appBarSearchController.clear();
      }
    }

    // 主题色配置 (传给组件用)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black45;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final fillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      // --- AppBar (包含搜索逻辑) ---
      appBar: _buildSearchAppBar(
          context,
          targetPlaylist.name,
          uiNotifier,
          theme
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => PlaylistSheet.show(context),
        tooltip: "切换播放列表",
        child: const Icon(Icons.queue_music),
      ),
      body: Stack(
        children: [

          Column(
            children: [
              FilterRowPanel(
                // 状态
                isFilterOpen: uiState.isFilterOpen,
                keyword: uiState.request.textKeyword, // 显示当前搜索词
                selectedTags: uiState.request.tags,
                totalCount: worksAsync.value?.pagination.totalCount ?? 0,

                // 回调
                onToggleFilter: () => uiNotifier.toggleFilterDrawer(),
                onClearKeyword: () {
                  uiNotifier.updateKeyword("", refreshData: true);
                  setState(() {
                    _isAppBarSearching = false;
                    _appBarSearchController.clear();
                  });
                },
                onRemoveTag: (tag) => uiNotifier.removeTag(tag.type, tag.name, refreshData: true),

                // 样式
                scrollController: _autoScrollController,
                bgColor: bgColor,
                textColor: textColor,
                subTextColor: subTextColor,
                fillColor: fillColor,
                primaryColor: primaryColor,
              ),
              Expanded(
                child: worksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('加载失败: $err'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(playlistWorksProvider(targetPlaylist.id)),
                          child: const Text('重试'),
                        )
                      ],
                    ),
                  ),
                  data: (response) {
                    final works = response.works;

                    final hasMore = works.length < response.pagination.totalCount;

                    if (works.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('没有找到相关作品', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    // 使用 RefreshIndicator 包裹列表支持下拉刷新
                    return RefreshIndicator(
                      onRefresh: () async {
                        return ref.refresh(playlistWorksProvider(targetPlaylist.id).future);
                      },
                      child: PlaylistCardGridView(
                        work: works,
                        padding: const EdgeInsets.all(12),
                        hasMore: hasMore,
                        onLoadMore: () {
                          // 调用数据 Provider 的 loadMore
                          ref.read(playlistWorksProvider(targetPlaylist.id).notifier).loadMore();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // 2. 遮罩层 (点击关闭筛选面板)
          if (uiState.isFilterOpen)
            Positioned.fill(
              // top: 0, // 覆盖整个 body
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => uiNotifier.toggleFilterDrawer(),
                child: Container(color: Colors.black12), // 稍微给点颜色
              ),
            ),

          // 3. 筛选抽屉组件 (FilterDrawerPanel)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0, // 从 body 顶部开始展示
            left: 0,
            right: 0,
            child: FilterDrawerPanel(
              isOpen: uiState.isFilterOpen,
              selectedFilterIndex: uiState.selectedFilterIndex,
              localSearchKeyword: uiState.localSearchKeyword,
              selectedTags: uiState.request.tags,

              tagsAsync: ref.watch(tagsProvider),
              circlesAsync: ref.watch(circlesProvider),
              vasAsync: ref.watch(vasProvider),

              onFilterIndexChanged: (index) => uiNotifier.setFilterIndex(index),
              onLocalSearchChanged: (val) => uiNotifier.setLocalSearchKeyword(val),
              onReset: () => uiNotifier.resetSelected(),
              onApply: () {
                uiNotifier.toggleFilterDrawer();
                uiNotifier.searchImmediately(); // 触发搜索
              },
              onToggleTag: (type, name) => uiNotifier.toggleTag(type, name, refreshData: false),
              getLoadingMessage: (type) => uiNotifier.getLoadingMessage(type),

              // --- 特殊筛选构建器 ---
              specialFilterBuilder: (ctx) {
                // 如果 AdvancedFilterPanel 还没重构，暂时这么传，或者你需要根据 AdvancedFilterPanel 的 API 调整
                return AdvancedFilterPanel(
                  // 直接传 uiState 中的 tags
                  selectedTags: uiState.request.tags,
                  // 直接传 uiNotifier 的方法
                  onToggleTag: (type, name) => uiNotifier.toggleTag(type, name, refreshData: false),
                  fillColor: fillColor,
                  textColor: textColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 独立的 AppBar 构建方法 ---
  PreferredSizeWidget _buildSearchAppBar(
      BuildContext context,
      String titleName,
      PlaylistNotifier uiNotifier,
      ThemeData theme,
      ) {
    final foregroundColor = theme.appBarTheme.foregroundColor ?? Colors.white;
    final searchBarFillColor = foregroundColor.withOpacity(0.15);

    return AppBar(
      title: _isAppBarSearching
          ? Container(
        height: 40,
        decoration: BoxDecoration(
          color: searchBarFillColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _appBarSearchController,
          autofocus: true,
          // 1. 移除 style 中的 height: 1.2，避免光标偏移或文字被截断
          style: TextStyle(
            color: foregroundColor,
            fontSize: 16,
          ),
          cursorColor: theme.colorScheme.secondary,
          textInputAction: TextInputAction.search,
          // 垂直居中核心配置
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            // 2. 调整 Padding，让文字在 40px 高度内垂直居中更自然
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            border: InputBorder.none,
            hintText: '搜索作品名或声优...',
            hintStyle: TextStyle(
              color: foregroundColor.withOpacity(0.6),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: foregroundColor.withOpacity(0.6),
            ),
            // 3. ✨ 核心修复：使用 ValueListenableBuilder 局部监听
            // 只有当文字长度变化时，才刷新这个 suffixIcon，而不是刷新整个 TextField
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _appBarSearchController,
              builder: (context, value, child) {
                if (value.text.isEmpty) {
                  return const SizedBox(); // 没字的时候不占位
                }
                return IconButton(
                  icon: Icon(Icons.cancel,
                      size: 18, color: foregroundColor.withOpacity(0.6)),
                  onPressed: () {
                    // 清空内容，不使用 setState，直接操作 controller
                    _appBarSearchController.clear();
                    uiNotifier.updateKeyword("", refreshData: true);
                  },
                );
              },
            ),
          ),
          onSubmitted: (value) {
            uiNotifier.updateKeyword(value, refreshData: true);
          },
        ),
      )
          : Text(
        OtherUtil.getDisplayName(titleName),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        if (_isAppBarSearching)
          TextButton(
            onPressed: () {
              setState(() {
                _isAppBarSearching = false;
                _appBarSearchController.clear();
              });
              uiNotifier.updateKeyword("", refreshData: true);
            },
            child: Text(
              "取消",
              style: TextStyle(color: foregroundColor, fontSize: 16),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "搜索",
            onPressed: () {
              setState(() {
                _isAppBarSearching = true;
              });
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}