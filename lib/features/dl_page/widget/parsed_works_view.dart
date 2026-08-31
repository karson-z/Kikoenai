import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/config/work_layout_config.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/scraper/scraper_storage.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/filter/filter_widget.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';
import 'package:kikoenai/features/album/model/album_detail_args.dart';
import 'package:kikoenai/features/category/widget/filter_row_panel.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'dl_library_toolbar.dart';

class ParseWorksView extends ConsumerStatefulWidget {
  const ParseWorksView({super.key, required this.work});

  final List<Work> work;

  @override
  ConsumerState<ParseWorksView> createState() => _ParseWorksViewState();
}

class _ParseWorksViewState extends ConsumerState<ParseWorksView> {
  final AutoScrollController _chipsScrollController = AutoScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late List<Work> _localWorks;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _localWorks = List<Work>.from(widget.work);

    final filter = ref.read(searchFilterProvider(FilterModule.dl));
    _searchController.text = filter.keyword ?? '';
  }

  @override
  void didUpdateWidget(covariant ParseWorksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.work != oldWidget.work) {
      _localWorks = List<Work>.from(widget.work);
      if (_localWorks.isEmpty) _isEditing = false;
    }
  }

  @override
  void dispose() {
    _chipsScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Work> _applyFilter(List<Work> works, SearchFilterState filter) {
    final keyword = filter.keyword?.trim().toLowerCase() ?? '';
    final result = works
        .where((work) {
          if (keyword.isNotEmpty) {
            final title = work.title?.toLowerCase() ?? '';
            final name = work.name?.toLowerCase() ?? '';
            final circle = work.circle?.name?.toLowerCase() ?? '';
            final rjCode = 'rj${work.id}'.toLowerCase();
            if (!title.contains(keyword) &&
                !name.contains(keyword) &&
                !circle.contains(keyword) &&
                !rjCode.contains(keyword)) {
              return false;
            }
          }

          if (filter.subtitleFilter == 1 && !(work.hasSubtitle ?? false)) {
            return false;
          }
          if (filter.subtitleFilter == 2 && (work.hasSubtitle ?? false)) {
            return false;
          }

          for (final tag in filter.selectedTags) {
            final matched = _workMatchesTag(work, tag);
            if (matched == null) continue;
            if (tag.isExclude ? matched : !matched) return false;
          }
          return true;
        })
        .toList(growable: false);

    return result;
  }

  bool? _workMatchesTag(Work work, SearchTag tag) {
    switch (tag.type) {
      case 'age':
        return AgeRatingEnum.fromValue(work.ageCategoryString).value ==
            tag.name;
      case 'circle':
        return work.circle?.name == tag.name;
      case 'va':
        return (work.vas ?? const []).any((item) => item.name == tag.name);
      case 'tag':
        return (work.tags ?? const []).any((item) => item.name == tag.name);
      case 'duration':
        final threshold = int.tryParse(tag.name);
        return threshold == null || work.duration == null
            ? false
            : work.duration! >= threshold;
      case 'rate':
        final threshold = double.tryParse(tag.name);
        return threshold == null || work.rateAverage2dp == null
            ? false
            : work.rateAverage2dp! >= threshold;
      case 'price':
        final threshold = int.tryParse(tag.name);
        return threshold == null || work.price == null
            ? false
            : work.price! >= threshold;
      case 'sell':
        final threshold = int.tryParse(tag.name);
        return threshold == null || work.dlCount == null
            ? false
            : work.dlCount! >= threshold;
      default:
        // 本地 Work 没有可靠的原始语言字段，语言条件保持不参与过滤。
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider(FilterModule.dl));
    final filterNotifier = ref.read(
      searchFilterProvider(FilterModule.dl).notifier,
    );
    final filteredWorks = _applyFilter(_localWorks, filter);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filterHeight = MediaQuery.sizeOf(context).height * 0.4;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black45;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final fillColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);

    ref.listen<String?>(
      searchFilterProvider(FilterModule.dl).select((state) => state.keyword),
      (previous, next) {
        final value = next ?? '';
        if (_searchController.text == value) return;
        _searchController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
    );
    ref.listen<SearchFilterState>(searchFilterProvider(FilterModule.dl), (
      previous,
      next,
    ) {
      if (previous == null ||
          next.selectedTags.length <= previous.selectedTags.length) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_chipsScrollController.hasClients) return;
        final keywordOffset = (next.keyword?.isNotEmpty ?? false) ? 1 : 0;
        _chipsScrollController.scrollToIndex(
          next.selectedTags.length - 1 + keywordOffset,
          preferPosition: AutoScrollPosition.end,
          duration: const Duration(milliseconds: 300),
        );
      });
    });

    final content = Column(
      children: [
        SizedBox(
          height: 44,
          child: FilterRowPanel(
            isFilterOpen: filter.isFilterOpen,
            keyword: filter.keyword,
            selectedTags: filter.selectedTags,
            totalCount: filteredWorks.length,
            onToggleFilter: () {
              _searchFocusNode.unfocus();
              filterNotifier.toggleFilterDrawer();
            },
            onClearKeyword: _clearKeyword,
            onRemoveTag: (tag) => filterNotifier.removeTag(tag.type, tag.name),
            scrollController: _chipsScrollController,
            bgColor: bgColor,
            textColor: textColor,
            subTextColor: subTextColor,
            fillColor: fillColor,
            primaryColor: theme.colorScheme.primary,
            horizontalPadding: 8,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomScrollView(
                  key: const PageStorageKey<String>('dl_library_content'),
                  physics: filter.isFilterOpen
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  slivers: _buildContentSlivers(filteredWorks),
                ),
              ),
              if (filter.isFilterOpen)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _searchFocusNode.unfocus();
                      filterNotifier.closeFilterDrawer();
                    },
                    child: Container(color: Colors.black12),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                right: 0,
                height: filter.isFilterOpen ? filterHeight : 0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: filterHeight,
                    child: SizedBox(
                      height: filterHeight,
                      child: Material(
                        color: bgColor,
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        child: FilterWidget(
                          type: FilterModule.dl,
                          onComplete: filterNotifier.closeFilterDrawer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return ScrollAwareToolbarLayout(
      notificationPredicate: (_) => true,
      toolbar: DlLibraryToolbar(
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        isEditing: _isEditing,
        hasWorks: _localWorks.isNotEmpty,
        onSearchChanged: (value) =>
            filterNotifier.updateKeyword(value.trim().isEmpty ? null : value),
        onClearSearch: _clearKeyword,
        onToggleEditing: () => setState(() => _isEditing = !_isEditing),
        onClearAll: _handleClearAll,
      ),
      child: content,
    );
  }

  List<Widget> _buildContentSlivers(List<Work> works) {
    if (_localWorks.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView()),
      ];
    }
    if (works.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildNoMatchView()),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        sliver: SliverGrid.builder(
          itemCount: works.length,
          gridDelegate: _getGridDelegate(context),
          itemBuilder: (context, index) => _buildEditableGridCard(works[index]),
        ),
      ),
      SliverToBoxAdapter(child: _buildFooter(context, works.length)),
    ];
  }

  Widget _buildEditableGridCard(Work work) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(ignoring: _isEditing, child: _buildWorkCard(work)),
        if (_isEditing) _buildDeleteButton(work),
      ],
    );
  }

  Widget _buildWorkCard(Work work) {
    return WorkCard(
      id: work.id,
      title: work.title,
      name: work.name,
      circleName: work.circle?.name,
      mainCoverUrl: work.mainCoverUrl,
      heroTag: work.effectiveHeroTag,
      hasSubtitle: work.hasSubtitle,
      ageCategoryString: work.ageCategoryString,
      release: work.release,
      vas: work.vas,
      tags: work.tags,
      onTap: () => context.push(
        AppRoutes.detail,
        extra: AlbumDetailArgs(work: work, mode: AlbumDetailMode.dlLibrary),
      ),
    );
  }

  Widget _buildDeleteButton(Work work) {
    return Positioned(
      top: 6,
      right: 6,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleDeleteSingle(work),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  void _clearKeyword() {
    _searchController.clear();
    ref
        .read(searchFilterProvider(FilterModule.dl).notifier)
        .updateKeyword(null);
  }

  void _handleDeleteSingle(Work work) {
    ScraperStorage().deleteWork(work.id);
    setState(() {
      _localWorks.removeWhere((item) => item.id == work.id);
      if (_localWorks.isEmpty) _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移除 ${work.id} 的缓存数据'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleClearAll() async {
    final confirm = await KikoenaiDialog.show<bool>(
      context: context,
      builder: (context) => KikoenaiAlertDialog(
        titleText: '全部清空',
        contentText: '确定要删除本地所有已解析的作品元数据缓存吗？此操作不可恢复。',
        actions: [
          KikoenaiAlertDialog.textAction(
            context,
            label: '取消',
            onPressed: () => Navigator.pop(context, false),
          ),
          KikoenaiAlertDialog.textAction(
            context,
            label: '确认清空',
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ScraperStorage().clearAll();
    if (!mounted) return;

    setState(() {
      _localWorks.clear();
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已清空全部解析缓存')));
  }

  SliverGridDelegate _getGridDelegate(BuildContext context) {
    final layout = WorkLayoutConfig.card(context);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      crossAxisSpacing: layout.horizontalSpacing,
      mainAxisSpacing: layout.verticalSpacing,
      childAspectRatio: 0.75,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text('这里什么都没有哦', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildNoMatchView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text('没有符合筛选条件的作品', style: TextStyle(color: Colors.grey.shade500)),
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

  Widget _buildFooter(BuildContext context, int visibleCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Text(
        '已显示 $visibleCount / ${_localWorks.length} 部作品',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
