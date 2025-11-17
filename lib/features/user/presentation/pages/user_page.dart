import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:name_app/core/widgets/common/login_dialog_manager.dart';
import 'package:name_app/features/user/data/models/limit_work_info.dart';
import 'package:name_app/features/user/presentation/widget/work_list_layout.dart';
import '../../../../core/theme/theme_view_model.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import '../view_models/provider/tab_bar_provider.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage>
    with SingleTickerProviderStateMixin {
  final tabs = const ["观看历史", "正在追", "准备追", "已追完"];

  final double expandedHeight = 260;
  final double avatarMaxSize = 96;
  final double avatarMinSize = 40;
  final double avatarTopMargin = 12;
  final double avatarLeftMargin = 16;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // 确保 initState 在 State 对象生命周期中只运行一次

    // 在 initState 中创建 TabController
    final tabState = ref.read(tabBarProvider);
    _tabController = TabController(
      length: tabState.tabs.length,
      vsync: this,
      initialIndex: tabState.currentIndex,
    );

    // 修复 1: 将监听器移到 initState，确保只添加一次
    _tabController!.addListener(() {
      // 避免在 index 变化过程中执行 setIndex
      if (!_tabController!.indexIsChanging) {
        // 修复 2: 使用 read 而不是 watch 来读取 notifier
        ref.read(tabBarProvider.notifier).setIndex(_tabController!.index);
      }
    });
  }

  @override
  void dispose() {
    // 修复 3: 移除监听器并销毁 Controller，防止内存泄漏
    _tabController?.removeListener(_tabControllerListener); // 需要一个命名函数
    _tabController?.dispose();
    super.dispose();
  }

  // 辅助函数，用于 dispose 时移除监听器
  void _tabControllerListener() {
    if (!_tabController!.indexIsChanging) {
      ref.read(tabBarProvider.notifier).setIndex(_tabController!.index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 移除这里重复的逻辑，保持方法干净
  }

  @override
  Widget build(BuildContext context) {
    final themeStateAsync = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final isDark = themeStateAsync.value?.mode == ThemeMode.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final authStateAsync = ref.watch(authNotifierProvider);
    final tabState = ref.watch(tabBarProvider);

    return Scaffold(
      backgroundColor: bg,
      body: authStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (auth) {
          if (!auth.isLoggedIn || auth.currentUser == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => LoginDialogManager().showLoginDialog(),
                child: const Text('请先登录'),
              ),
            );
          }

          final user = auth.currentUser!;

          return DefaultTabController(
            length: tabs.length,
            initialIndex: tabState.currentIndex,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: expandedHeight,
                  automaticallyImplyLeading: false,
                  backgroundColor: bg,
                  actions: [
                    IconButton(
                      tooltip: isDark ? '切换为浅色模式' : '切换为深色模式',
                      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                      onPressed: themeNotifier.toggleLightDark,
                    ),
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final t = ((expandedHeight - constraints.maxHeight) /
                          (expandedHeight - kToolbarHeight))
                          .clamp(0.0, 1.0);

                      final avatarSize =
                          avatarMaxSize - (avatarMaxSize - avatarMinSize) * t;
                      final avatarLeft = (MediaQuery.of(context).size.width / 2 -
                          avatarSize / 2) *
                          (1 - t) +
                          avatarLeftMargin * t;
                      final avatarTop =
                          (expandedHeight - avatarSize / 2 - 40) * (1 - t) +
                              avatarTopMargin * t;
                      final nameLeft = avatarLeft + avatarSize + 12;
                      final nameOpacity = t;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  "assets/images/bg1.avif",
                                  fit: BoxFit.cover,
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 120,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black26,
                                          Colors.black45,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: avatarLeft,
                            top: avatarTop,
                            child: SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: CircleAvatar(
                                radius: avatarSize / 2,
                                backgroundColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                backgroundImage: const AssetImage(
                                    "assets/images/avatar.jpg"),
                              ),
                            ),
                          ),
                          Positioned(
                            left: nameLeft,
                            top: avatarTop + avatarSize / 4,
                            child: Opacity(
                              opacity: nameOpacity,
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TabBar(
                      controller: _tabController,
                      tabs: tabs
                          .map((t) => Text(
                        t,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ))
                          .toList(),
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      isScrollable: true,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                // 你的列表 SliverGrid
                ResponsiveListGrid(work:[]),
                // 占位 Sliver，确保 AppBar 可收缩
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: 100), // 根据内容多少调整
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
