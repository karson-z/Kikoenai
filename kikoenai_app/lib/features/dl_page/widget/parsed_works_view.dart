import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/config/work_layout_config.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:kikoenai/core/widgets/filter/filter_widget.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/features/category/widget/filter_row_panel.dart';

class ParseWorksView extends ConsumerStatefulWidget {
  final List<Work> work;

  const ParseWorksView({super.key, required this.work});

  @override
  ConsumerState<ParseWorksView> createState() => _ParseWorksViewState();
}

class _ParseWorksViewState extends ConsumerState<ParseWorksView> {
  // 控制是否处于编辑模式
  bool _isEditing = false;

  late List<Work> _localWorks;

  /// 筛选行横向 chips 的滚动控制器（FilterRowPanel 使用）。
  final AutoScrollController _chipsScrollController = AutoScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化时，将外部传入的静态数据拷贝一份给本地状态
    _localWorks = List.from(widget.work);
  }

  @override
  void dispose() {
    _chipsScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParseWorksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果父组件传入的数据发生了实质性改变，重新同步到本地
    if (widget.work != oldWidget.work) {
      _localWorks = List.from(widget.work);
    }
  }

  /// 将 DL库筛选状态应用到本地作品列表（仅当前页面）。
  List<Work> _applyFilter(List<Work> works, SearchFilterState filter) {
    final keyword = filter.keyword?.trim().toLowerCase() ?? '';
    return works.where((w) {
      // 1. 关键词：标题 / RJ编号 / 社团
      if (keyword.isNotEmpty) {
        final title = w.title?.toLowerCase() ?? '';
        final name = w.name?.toLowerCase() ?? '';
        final circle = w.circle?.name?.toLowerCase() ?? '';
        if (!title.contains(keyword) &&
            !name.contains(keyword) &&
            !circle.contains(keyword) &&
            !'${w.id}'.contains(keyword)) {
          return false;
        }
      }
      // 2. 字幕
      if (filter.subtitleFilter == 1 && !(w.hasSubtitle ?? false)) {
        return false;
      }
      if (filter.subtitleFilter == 2 && (w.hasSubtitle ?? false)) {
        return false;
      }
      // 3. 标签（含排除）
      for (final tag in filter.selectedTags) {
        final matched = _workMatchesTag(w, tag);
        if (matched == null) continue; // 暂不支持的类型忽略，避免误过滤
        if (tag.isExclude && matched) return false;
        if (!tag.isExclude && !matched) return false;
      }
      return true;
    }).toList();
  }

  /// 判断单个作品是否命中标签；返回 null 表示该类型本地无法匹配（忽略）。
  bool? _workMatchesTag(Work w, SearchTag tag) {
    switch (tag.type) {
      case 'age':
        return AgeRatingEnum.fromValue(w.ageCategoryString).value == tag.name;
      case 'circle':
        return w.circle?.name == tag.name;
      case 'va':
        return (w.vas ?? const []).any((v) => v.name == tag.name);
      case 'tag':
        return (w.tags ?? const []).any((t) => t.name == tag.name);
      default:
        // duration / rate / price / sell / lang：
        // Work 本地字段无法精确匹配范围值，暂不参与过滤。
        return null;
    }
  }

  /// 打开与分类页一致的筛选底部弹窗（FilterModule.dl，仅本页状态）。
  void _openFilterSheet() {
    showFilterBottomSheet(context, ref, FilterModule.dl);
  }

  @override
  Widget build(BuildContext context) {
    // 空状态
    if (_localWorks.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView()),
        ],
      );
    }

    final layout = WorkLayoutConfig.card(context);
    final filter = ref.watch(searchFilterProvider(FilterModule.dl));
    final filteredWorks = _applyFilter(_localWorks, filter);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // 筛选行（与分类页一致的 FilterRowPanel）
        SliverToBoxAdapter(
          child: FilterRowPanel(
            isFilterOpen: false,
            keyword: filter.keyword,
            selectedTags: filter.selectedTags,
            totalCount: filteredWorks.length,
            onToggleFilter: _openFilterSheet,
            onClearKeyword: () => ref
                .read(searchFilterProvider(FilterModule.dl).notifier)
                .updateKeyword(null),
            onRemoveTag: (tag) => ref
                .read(searchFilterProvider(FilterModule.dl).notifier)
                .removeTag(tag.type, tag.name),
            scrollController: _chipsScrollController,
            bgColor: theme.scaffoldBackgroundColor,
            textColor: isDark ? Colors.white70 : Colors.grey[700]!,
            subTextColor: isDark ? Colors.white54 : Colors.grey,
            fillColor: isDark
                ? const Color(0xFF212529)
                : const Color(0xFFF9FAFB),
            primaryColor: theme.colorScheme.primary,
          ),
        ),

        // 工具栏：关键词搜索 + 编辑/清空
        SliverToBoxAdapter(child: _buildToolbarRow(context)),

        // 无匹配结果
        if (filteredWorks.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildNoMatchView())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            sliver: SliverGrid.builder(
              itemCount: filteredWorks.length,
              gridDelegate: _getGridDelegate(
                layout.horizontalSpacing,
                layout.verticalSpacing,
              ),
              itemBuilder: (context, index) {
                final currentWork = filteredWorks[index];
                return _buildEditableCard(currentWork);
              },
            ),
          ),

        // 底部 Footer
        SliverToBoxAdapter(child: _buildFooter(context)),
      ],
    );
  }

  /// 工具栏：编辑/清空按钮（关键词搜索框已移到 AppBar）。
  Widget _buildToolbarRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 处于编辑模式时，显示“全部清空”按钮
          if (_isEditing)
            TextButton.icon(
              onPressed: _handleClearAll,
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text('全部清空', style: TextStyle(color: Colors.red)),
            ),
          // 编辑/完成 切换按钮
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            label: Text(_isEditing ? '完成' : '编辑'),
          ),
        ],
      ),
    );
  }

  /// 构建带有删除遮罩的卡片
  Widget _buildEditableCard(Work currentWork) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底层：原来的作品卡片。如果是编辑模式，屏蔽其点击事件防止误触播放
        IgnorePointer(
          ignoring: _isEditing,
          child: WorkCard(
            id: currentWork.id,
            title: currentWork.title,
            name: currentWork.name,
            circleName: currentWork.circle?.name,
            mainCoverUrl: currentWork.mainCoverUrl,
            heroTag: currentWork.effectiveHeroTag,
            hasSubtitle: currentWork.hasSubtitle,
            ageCategoryString: currentWork.ageCategoryString,
            release: currentWork.release,
            vas: currentWork.vas,
            tags: currentWork.tags,
            onTap: () {
              context.push(AppRoutes.detail, extra: {'work': currentWork});
            },
          ),
        ),

        // 顶层：编辑模式下的删除按钮
        if (_isEditing)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6), // 半透明黑色背景让白色图标更清晰
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _handleDeleteSingle(currentWork),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 处理单个删除
  void _handleDeleteSingle(Work work) {
    // 1. 删底层数据库
    ScraperStorage().deleteWork(work.id);
    setState(() {
      _localWorks.removeWhere((w) => w.id == work.id);

      // 可选：如果删光了，自动退出编辑模式
      if (_localWorks.isEmpty) {
        _isEditing = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移除 ${work.id} 的缓存数据'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 处理全部清空
  Future<void> _handleClearAll() async {
    final confirm = await KikoenaiDialog.show<bool>(
      context: context,
      builder: (context) => KikoenaiAlertDialog(
        titleText: "全部清空",
        contentText: "确定要删除本地所有已解析的作品元数据缓存吗？此操作不可恢复。",
        actions: [
          KikoenaiAlertDialog.textAction(
            context,
            label: "取消",
            onPressed: () => Navigator.pop(context, false),
          ),
          KikoenaiAlertDialog.textAction(
            context,
            label: "确认清空",
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. 删底层数据库
      await ScraperStorage().clearAll();

      if (mounted) {
        // 2. 【核心修复 6】：清空内存里的 UI 列表，并退出编辑模式
        setState(() {
          _localWorks.clear();
          _isEditing = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已清空全部解析缓存')));
      }
    }
  }

  SliverGridDelegate _getGridDelegate(
    double horizontalSpacing,
    double verticalSpacing,
  ) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      crossAxisSpacing: horizontalSpacing,
      mainAxisSpacing: verticalSpacing,
      childAspectRatio: 0.75,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text("这里什么都没有哦", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  /// 有数据但筛选无匹配时的提示。
  Widget _buildNoMatchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_alt_off, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "没有符合筛选条件的作品",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final notifier = ref.read(
                searchFilterProvider(FilterModule.dl).notifier,
              );
              notifier.resetSelected();
              notifier.updateKeyword(null);
              notifier.setSubtitleFilter(0);
            },
            child: const Text('重置筛选'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }
}
