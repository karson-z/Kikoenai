import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/work_progress.dart';
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
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(reviewListProvider);
    final params = ref.watch(reviewParamsProvider);
    final notifier = ref.read(reviewParamsProvider.notifier);

    // --- 1. 之前修复分页 Bug 的逻辑 (保持不变) ---
    final pagination = reviewAsync.value?.pagination;
    int totalPage = 1;
    bool shouldShowPagination = false;

    if (pagination != null && pagination.pageSize > 0) {
      shouldShowPagination = true;
      totalPage = (pagination.totalCount / pagination.pageSize).ceil();
      if (totalPage < 1) totalPage = 1;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ReviewHeader(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                  notifier.updateFilter(
                    filter: index == 0 ? null : WorkProgress.marked.value,
                  );
                });
              },
            ),

            // --- 2. 使用 Dart 3 Switch 表达式处理列表状态 ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(reviewListProvider.future),
                // 这里使用了你要求的 switch 语法
                child: switch (reviewAsync) {
                  AsyncValue(:final value?) when value.works.isEmpty =>
                      _buildEmptyView(),
                  AsyncValue(:final value?) => ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: value.works.length,
                    itemBuilder: (context, index) {
                      return WorkListCard(work: value.works[index]);
                    },
                  ),
                // Case C: 发生错误 (提取 error 变量用于显示)
                  AsyncValue(:final error?) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('加载失败: $error', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => ref.refresh(reviewListProvider),
                          child: const Text("重试"),
                        )
                      ],
                    ),
                  ),

                // Case D: 正在加载 (且没有旧数据)
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ],
        ),
      ),

      // --- 3. 底部导航栏逻辑 (保持不变) ---
      bottomNavigationBar: shouldShowPagination
          ? PaginationBar(
        currentPage: params.page,
        totalPages: totalPage,
        onPageChanged: (newPage) => notifier.setPage(newPage),
      )
          : null,
    );
  }

  /// 这里的 _buildEmptyView 必须支持滚动，否则 RefreshIndicator 可能无法触发
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