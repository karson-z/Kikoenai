import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/marked/presentation/page/review_page.dart';
import 'package:kikoenai/features/playlist/presentation/page/playlist_page.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import '../../../download/presentation/page/download_page.dart';
import 'history_page.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage>
    with SingleTickerProviderStateMixin {
  final tabs = const ["观看历史", "我的收藏", "播放列表", "下载列表"];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme; // 获取当前主题色板

    return SafeArea(
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                elevation: 0,
                centerTitle: false, // 确保标题内容靠左
                // 核心修改：动态监听高度计算透明度的折叠 Title
                title: Builder(
                  builder: (context) {
                    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
                    final double opacity = settings == null
                        ? 1.0
                        : (1.0 - (settings.currentExtent - settings.minExtent) / 40.0).clamp(0.0, 1.0);

                    // 如果完全透明，直接返回空盒子节省渲染开销
                    if (opacity <= 0.0) return const SizedBox.shrink();

                    return Opacity(
                      opacity: opacity,
                      child: switch (authStateAsync) {
                        AsyncValue(:final value?) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SimpleExtendedImage.avatar(
                              width: 32,
                              height: 32,
                              'assets/images/138787745_p0_master1200.jpg',
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                value.currentUser?.loggedIn == true
                                    ? value.currentUser!.name
                                    : '未登录',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      context.push(AppRoutes.settings);
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 60),
                    alignment: Alignment.bottomLeft,
                    child: switch (authStateAsync) {
                      AsyncValue(:final value?) => Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SimpleExtendedImage.avatar(
                            width: 80,
                            height: 80,
                            'assets/images/138787745_p0_master1200.jpg',
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        value.currentUser?.loggedIn == true
                                            ? value.currentUser!.name
                                            : '未登录',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (value.currentUser?.loggedIn == true) ...[
                                  Wrap(
                                    spacing: 16.0,
                                    runSpacing: 4.0,
                                    children: [
                                      _buildStatText(context, 'UID', value.currentUser?.recommenderUuid ?? '-'),
                                      _buildStatText(context, '邮箱', value.currentUser?.email ?? '-'),
                                    ],
                                  ),
                                ] else ...[
                                  Text(
                                    '登录后可查看和编辑个人资料',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant, // 使用次级文字颜色
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!(value.currentUser?.loggedIn == true))
                            FilledButton(
                              onPressed: () => context.push(AppRoutes.login),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('登录'),
                            ),
                        ],
                      ),
                      AsyncValue(error: != null) => Center(
                        child: Text(
                          '获取用户信息失败',
                          style: TextStyle(color: colorScheme.error), // 使用主题的错误色
                        ),
                      ),
                      AsyncValue() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    },
                  ),
                ),
                bottom: TabBar(
                  tabAlignment: TabAlignment.start,
                  controller: _tabController,
                  isScrollable: true,
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: const [
              HistoryPage(),
              ReviewPage(),
              PlaylistPage(),
              DownloadPage(),
            ],
          ),
        ),
      ),
    );
  }

  // 增加 BuildContext 参数以获取主题颜色
  Widget _buildStatText(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    // 改用 Text.rich 替代 RichText，这样能更好地继承默认的文本样式
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        children: [
          TextSpan(
            text: '$value ',
            style: TextStyle(fontWeight: FontWeight.w400, color: colorScheme.onSurface),
          ),
          TextSpan(text: label,style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface,fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}