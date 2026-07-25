import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/presentation/widget/work_grid_layout.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../viewmodel/provider/work_provider.dart';

/// 定义数据源类型
enum WorkDataSource {
  hot,
  recommended,
  newest,
}

class SmartWorksSliverGrid extends ConsumerWidget {
  final WorkDataSource source;

  const SmartWorksSliverGrid({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 根据传入的枚举，动态获取对应的 State 和 Notifier 方法
    AsyncValue<WorkState> asyncState;
    VoidCallback onLoadMore;
    VoidCallback onRetry;

    switch (source) {
      case WorkDataSource.hot:
        asyncState = ref.watch(hotWorksProvider);
        onLoadMore = () => ref.read(hotWorksProvider.notifier).loadMore();
        onRetry = () => ref.read(hotWorksProvider.notifier).refresh();
        break;
      case WorkDataSource.recommended:
        asyncState = ref.watch(recommendedWorksProvider);
        onLoadMore = () => ref.read(recommendedWorksProvider.notifier).loadMore();
        onRetry = () => ref.read(recommendedWorksProvider.notifier).refresh();
        break;
      case WorkDataSource.newest:
        asyncState = ref.watch(newWorksProvider);
        onLoadMore = () => ref.read(newWorksProvider.notifier).loadMore();
        onRetry = () => ref.read(newWorksProvider.notifier).refresh();
        break;
    }

    // 2. 根据 AsyncValue 的不同状态，渲染不同的 Sliver
    return asyncState.when(
      // --- 数据获取成功：直接投喂给下层的 ResponsiveCardGrid ---
      data: (state) {
        return ResponsiveCardGrid(
          work: state.works,
          hasMore: state.hasMore,
          isLoading: state.isLoading,
          onLoadMore: onLoadMore,
        );
      },

      // --- 首次加载中：显示骨架屏或 Loading ---
      // 注意：由于外层是 CustomScrollView，这里必须返回 Sliver 家族的组件
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),

      // --- 网络错误/解析错误：显示错误提示与重试按钮 ---
      error: (err, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '加载失败，请检查网络',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              )
            ],
          ),
        ),
      ),
    );
  }
}