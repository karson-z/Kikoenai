import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/work_progress.dart';
import 'package:kikoenai/core/widgets/common/guest_placeholder_view.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/service/cache/cache_service.dart';
import '../../../../core/widgets/pagination/pagination_bar.dart';
import '../provider/review_provider.dart';
import '../widget/review_header.dart';
import '../widget/review_work_card.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {

  @override
  Widget build(BuildContext context) {
    final isLogin = CacheService.instance.getAuthSession() != null;
    if (!isLogin) {
      return Center(child: GuestPlaceholderView(onLoginTap: (){
        context.push(AppRoutes.login);
      }));
    }
    // 1. 监听数据状态 (Loading / Data / Error)
    final reviewAsync = ref.watch(reviewListProvider);
    // 2. 获取 Notifier 实例
    final notifier = ref.read(reviewListProvider.notifier);
    final params = notifier.params;

    // 计算 Tab Index
    final int currentTabIndex = params.filter != null ? 1 : 0;
    final pagination = reviewAsync.value?.pagination;
    int totalPage = 1;
    bool shouldShowPagination = false;
    if (pagination != null && pagination.pageSize > 0) {
      shouldShowPagination = true;
      totalPage = (pagination.totalCount / pagination.pageSize).ceil();
    }

    return Scaffold(
      body: Column(
        children: [
          ReviewHeader(
            selectedIndex: currentTabIndex,
            onTabSelected: (index) {
              notifier.updateFilter(
                filter: index == 0 ? null : WorkProgress.marked.value,
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              // 调用 notifier 的 refresh 方法
              onRefresh: () => notifier.refresh(),
              child: switch (reviewAsync) {
                AsyncValue(:final value?) when value.works.isEmpty => _buildEmptyView(),
                AsyncValue(:final value?) => ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: value.works.length,
                  itemBuilder: (context, index) {
                    return WorkListCard(work: value.works[index]);
                  },
                ),
                AsyncValue(:final error?) => Text('Error: $error'),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: shouldShowPagination
          ? PaginationBar(
        currentPage: params.page,
        totalPages: totalPage,
        onPageChanged: (newPage) => notifier.setPage(newPage),
      )
          : null,
    );
  }

  Widget _buildEmptyView() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无数据', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}