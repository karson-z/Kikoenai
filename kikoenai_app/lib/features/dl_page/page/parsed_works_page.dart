import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/utils/scraper/scraper_controller.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';

import '../widget/parsed_works_view.dart';
import '../widget/scraper_drawer.dart';

class ParsedWorksPage extends ConsumerWidget {
  const ParsedWorksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(scraperQueueProvider);
    final queueCount = queueState.pending.length + queueState.processing.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        // 标题区直接放关键词搜索框（原 "DL库" 标题已移除）
        title: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: _DlAppBarSearch(),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: '解析队列',
                icon: Badge(
                  isLabelVisible: queueCount > 0,
                  label: Text(queueCount.toString()),
                  child: const Icon(Icons.swap_vert_circle_outlined),
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: const ScraperQueueDrawer(),
      body: ValueListenableBuilder(
        valueListenable: AppStorage.scraperWorkBox.listenable(),
        builder: (context, box, child) {
          return ParseWorksView(work: box.values.toList());
        },
      ),
    );
  }
}

/// AppBar 内的关键词搜索框：绑定 [FilterModule.dl] 筛选状态（仅当前页面）。
class _DlAppBarSearch extends ConsumerStatefulWidget {
  const _DlAppBarSearch();

  @override
  ConsumerState<_DlAppBarSearch> createState() => _DlAppBarSearchState();
}

class _DlAppBarSearchState extends ConsumerState<_DlAppBarSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchFilterProvider(FilterModule.dl)).keyword ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 外部（如删除关键词 chip）清空关键词时，同步输入框内容。
    ref.listen(
      searchFilterProvider(FilterModule.dl).select((s) => s.keyword),
      (prev, next) {
        final value = next ?? '';
        if (_controller.text != value) {
          _controller.text = value;
        }
      },
    );
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        isDense: true,
        hintText: '搜索标题 / RJ / 社团',
        prefixIcon: const Icon(Icons.search, size: 18),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: '清空',
              iconSize: 16,
              onPressed: () => ref
                  .read(searchFilterProvider(FilterModule.dl).notifier)
                  .updateKeyword(null),
              icon: const Icon(Icons.close),
            );
          },
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => ref
          .read(searchFilterProvider(FilterModule.dl).notifier)
          .updateKeyword(v.isEmpty ? null : v),
    );
  }
}
