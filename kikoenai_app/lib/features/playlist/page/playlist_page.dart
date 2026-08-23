import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/service/site/site_availability.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/common/guest_placeholder_view.dart';
import 'package:kikoenai/core/widgets/filter/filter_widget.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../../core/widgets/filter/provider/filter_search_notifier.dart';
import '../../../../core/widgets/menu/float_menu_button.dart';
import '../../settings/provider/setting_provider.dart';
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

  late FocusNode _filterSearchFocusNode;

  late bool isFabOpen = true;
  // AppBar 搜索框控制器
  final TextEditingController _appBarSearchController = TextEditingController();

  // 控制 AppBar 是否显示搜索输入框 (仅 UI 表现，数据在 Provider 中)
  bool _isAppBarSearching = false;

  @override
  void initState() {
    super.initState();
    _autoScrollController = AutoScrollController(axis: Axis.horizontal);
    _filterSearchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _appBarSearchController.dispose();
    _filterSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取当前目标歌单
    final targetPlaylist = ref.watch(defaultMarkTargetPlaylistProvider);
    final isLogin = ref.watch(authNotifierProvider).value?.isLoggedIn ?? false;
    final canOpenAuth = ref.watch(
      surfaceAvailableProvider(AppSurface.authPage),
    );
    final canLogin = ref.watch(
      surfaceAvailableProvider(AppSurface.loginAction),
    );

    if (!isLogin) {
      return Scaffold(
        body: GuestPlaceholderView(
          onLoginTap: canOpenAuth
              ? () {
                  context.go(AppRoutes.login);
                }
              : null,
          buttonText: canLogin ? '立即登录' : '立即注册',
        ),
      );
    }
    if (targetPlaylist == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(defaultMarkTargetPlaylistProvider.notifier)
            .fetchAndCacheDefault();
      });
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final worksAsync = ref.watch(playlistWorksProvider(targetPlaylist.id));
    // 主题色配置 (传给组件用)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildSearchAppBar(context, targetPlaylist.name, ref, theme),
      floatingActionButton: MorphingCapsuleFab(
        isExpanded: isFabOpen,
        fabSize: 52,
        expandedHeight: 52,
        direction: AxisDirection.left,
        fabIcon: Icons.add,
        actions: [
          MorphingAction(
            icon: Icons.tune,
            label: '筛选',
            onTap: () {
              showFilterBottomSheet(
                context,
                ref,
                FilterModule.playlist,
                onComplete: () {
                  ref.invalidate(playlistWorksProvider);
                },
              );
            },
          ),
          MorphingAction(
            icon: Icons.menu,
            label: '播放列表',
            onTap: () {
              PlaylistSheet.show(context);
            },
          ),
        ],
      ),
      body: SizedBox(
        child: worksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $err'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(playlistWorksProvider(targetPlaylist.id)),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
          data: (pagingState) {
            return RefreshIndicator(
              onRefresh: () async {
                return ref.refresh(
                  playlistWorksProvider(targetPlaylist.id).future,
                );
              },
              child: PlaylistCardGridView(
                pagingState: pagingState,
                padding: const EdgeInsets.all(12),
                fetchNextPage: () {
                  ref
                      .read(playlistWorksProvider(targetPlaylist.id).notifier)
                      .fetchNextPage();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar(
    BuildContext context,
    String titleName,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final foregroundColor = theme.appBarTheme.foregroundColor ?? Colors.white;
    final searchBarFillColor = foregroundColor.withOpacity(0.15);
    final uiNotifier = ref.read(
      searchFilterProvider(FilterModule.playlist).notifier,
    );
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
                style: TextStyle(color: foregroundColor, fontSize: 16),
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
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _appBarSearchController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return const SizedBox(); // 没字的时候不占位
                      }
                      return IconButton(
                        icon: Icon(
                          Icons.cancel,
                          size: 18,
                          color: foregroundColor.withOpacity(0.6),
                        ),
                        onPressed: () {
                          // 清空内容，不使用 setState，直接操作 controller
                          _appBarSearchController.clear();
                          uiNotifier.updateKeyword("");
                        },
                      );
                    },
                  ),
                ),
                onSubmitted: (value) {
                  uiNotifier.updateKeyword(value);
                  ref.invalidate(playlistWorksMutationProvider);
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
              uiNotifier.updateKeyword("");
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
