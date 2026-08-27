import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/marked/page/review_page.dart';
import 'package:kikoenai/features/playlist/page/playlist_page.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/service/site/site_api_provider.dart';
import '../../../core/service/site/site_availability.dart';
import '../../auth/provider/auth_provider.dart';
import '../../history/page/history_page.dart';

class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authNotifierProvider);
    final activeSiteId = ref.watch(activeSiteIdProvider);
    final availableSurfaces = ref.watch(availableSurfacesProvider);
    final canOpenAuth = availableSurfaces.contains(AppSurface.authPage);
    final canLogin = availableSurfaces.contains(AppSurface.loginAction);
    final tabs = <({String label, Widget page})>[
      (label: '观看历史', page: const HistoryPage()),
      if (availableSurfaces.contains(AppSurface.userReviewsTab))
        (label: '我的收藏', page: const ReviewPage()),
      if (availableSurfaces.contains(AppSurface.userPlaylistsTab))
        (label: '播放列表', page: const PlaylistPage()),
    ];
    final colorScheme = Theme.of(context).colorScheme; // 获取当前主题色板

    return DefaultTabController(
      key: ValueKey(activeSiteId),
      length: tabs.length,
      child: SafeArea(
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      expandedHeight: 220.0,
                      pinned: true,
                      elevation: 0,
                      centerTitle: false, // 确保标题内容靠左
                      // 核心修改：动态监听高度计算透明度的折叠 Title
                      title: Builder(
                        builder: (context) {
                          final settings = context
                              .dependOnInheritedWidgetOfExactType<
                                FlexibleSpaceBarSettings
                              >();
                          final double opacity = settings == null
                              ? 1.0
                              : (1.0 -
                                        (settings.currentExtent -
                                                settings.minExtent) /
                                            40.0)
                                    .clamp(0.0, 1.0);

                          // 如果完全透明，直接返回空盒子节省渲染开销
                          if (opacity <= 0.0) return const SizedBox.shrink();

                          return Opacity(
                            opacity: opacity,
                            child: switch (authStateAsync) {
                              AsyncValue(:final value?) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SimpleExtendedImage.avatar(
                                    width: 32,
                                    height: 32,
                                    Assets.images.logo.path,
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
                          tooltip: '下载管理',
                          icon: const Icon(Icons.download_outlined),
                          onPressed: () {
                            context.push(AppRoutes.downloads);
                          },
                        ),
                        IconButton(
                          tooltip: '设置',
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            context.push(AppRoutes.settings);
                          },
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 60,
                          ),
                          alignment: Alignment.bottomLeft,
                          child: switch (authStateAsync) {
                            AsyncValue(:final value?) => Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SimpleExtendedImage.avatar(
                                  width: 80,
                                  height: 80,
                                  Assets.images.logo.path,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              value.currentUser?.loggedIn ==
                                                      true
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
                                      if (value.currentUser?.loggedIn ==
                                          true) ...[
                                        Wrap(
                                          spacing: 16.0,
                                          runSpacing: 4.0,
                                          children: [
                                            _buildStatText(
                                              context,
                                              'UID',
                                              value
                                                      .currentUser
                                                      ?.recommenderUuid ??
                                                  '-',
                                            ),
                                            _buildStatText(
                                              context,
                                              '邮箱',
                                              value.currentUser?.email ?? '-',
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Text(
                                          '登录后可查看和编辑个人资料',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme
                                                .onSurfaceVariant, // 使用次级文字颜色
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!(value.currentUser?.loggedIn == true) &&
                                    canOpenAuth)
                                  FilledButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.login),
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(canLogin ? '登录' : '注册'),
                                  ),
                              ],
                            ),
                            AsyncValue(error: != null) => Center(
                              child: Text(
                                '获取用户信息失败',
                                style: TextStyle(
                                  color: colorScheme.error,
                                ), // 使用主题的错误色
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
                        isScrollable: true,
                        tabs: tabs
                            .map((item) => Tab(text: item.label))
                            .toList(),
                      ),
                    ),
                  ];
                },
            body: TabBarView(children: tabs.map((item) => item.page).toList()),
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
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
