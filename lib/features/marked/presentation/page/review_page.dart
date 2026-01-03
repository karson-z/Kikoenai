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
    final pagination = reviewAsync.value?.pagination;
    final int totalCount = pagination?.totalCount ?? 0;
    final int pageSize = pagination?.pageSize ?? 0;
    final int totalPage = (pageSize > 0)
        ? (totalCount / pageSize).ceil()
        : 1;
    return Scaffold(
      // 移除默认的 AppBar
      body: SafeArea(
        child: Column(
          children: [
            ReviewHeader(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                  notifier.updateFilter(filter: index == 0 ? null : WorkProgress.marked.value);
                });
              },
            ),

            // 2. 放置列表内容
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(reviewListProvider.future),
                child: reviewAsync.when(
                  data: (pagedData) {
                    final works = pagedData.works;
                    if (works.isEmpty) return _buildEmptyView();
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: works.length,
                      itemBuilder: (context, index) {
                        return WorkListCard(
                          work: works[index],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('加载失败: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PaginationBar(
        currentPage: params.page,
        totalPages: totalPage,
        onPageChanged: (newPage) {
          notifier.setPage(newPage);
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无数据', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}