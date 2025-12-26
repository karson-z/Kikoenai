import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/features/search/presentation/provider/search_provider.dart';
import '../../../../core/widgets/layout/app_search_app_bar.dart';
import '../../../category/presentation/viewmodel/provider/category_data_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialKeyword = ref.read(categoryUiProvider).keyword ?? '';
    _controller = TextEditingController(text: initialKeyword);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 执行搜索的统一逻辑
  void _performSearch(String val) {
    if (val.trim().isEmpty) return;

    debugPrint('提交关键字: $val');

    ref.read(searchHistoryProvider.notifier).add(val);

    // 2. 更新分类页面的关键字状态
    ref.read(categoryUiProvider.notifier).updateKeyword(val);
    ref.read(categoryUiProvider.notifier).searchImmediately();

    // 3. 跳转到结果展示页 (CategoryPage)
    context.go(AppRoutes.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchAppBar(
            controller: _controller,
            hintText: "搜索作品名称、ID",
            leading: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                context.pop();
              },
            ),
            onSubmitted: _performSearch,
          ),
          Expanded(
            child: _buildHistoryBody(),
          ),
        ],
      ),
    );
  }

  /// 构建历史记录区域
  Widget _buildHistoryBody() {
    final historyState = ref.watch(searchHistoryProvider);

    return historyState.when(
      data: (historyList) {
        if (historyList.isEmpty) {
          return const Center(
            child: Text(
              "暂无搜索历史",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "搜索历史",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () {
                      _showClearHistoryDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // 历史记录列表 (使用 Wrap 流式布局，视觉效果更好)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: historyList.map((keyword) {
                    return InputChip(
                      // 1. 文本内容
                      label: Text(keyword),

                      // 2. 左侧图标 (保持你原来的设计)
                      avatar: const Icon(Icons.history, size: 16, color: Colors.grey),

                      // 3. 点击主体：执行搜索
                      onPressed: () {
                        _controller.text = keyword;
                        _performSearch(keyword);
                      },

                      onDeleted: () {
                        ref.read(searchHistoryProvider.notifier).remove(keyword);
                      },

                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: Colors.grey,

                      // 6. 样式调整
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      error: (e, s) => const SizedBox.shrink(), // 出错时不显示
      loading: () => const SizedBox.shrink(), // 加载快，通常不需要转圈
    );
  }

  /// 清空确认弹窗
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("清空历史记录"),
          content: const Text("确定要删除所有搜索历史吗？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                ref.read(searchHistoryProvider.notifier).clear();
                Navigator.of(context).pop();
              },
              child: const Text("清空"),
            ),
          ],
        );
      },
    );
  }
}