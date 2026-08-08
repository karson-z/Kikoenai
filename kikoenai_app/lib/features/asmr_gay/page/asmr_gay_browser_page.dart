import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai/core/widgets/bread_crumb_bar/file_bread_crumb_bar.dart';

import 'package:kikoenai/features/album/widget/file_box.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

/// asmr.gay 文件浏览器页面。
///
/// 当用户切换到 asmr.gay 站点时，首页（[AlbumPage]）会渲染本页面替代
/// 原有的"热门/推荐/最新"作品列表。
///
/// ### 页面结构
///
/// - **无 AppBar**：搜索框作为 sliver 直接放在 [CustomScrollView] 顶部，
///   与列表同滚动，配合 [RefreshIndicator] 实现下拉刷新。
/// - **状态保持**：进入子目录时通过 [Navigator.push] 推入新的
///   [AsmrGayBrowserPage] 实例，每个目录层级独立持有自己的状态
///   （节点列表、滚动位置、分页游标），返回上一级时父页面状态完整保留。
/// - **搜索态**：在搜索框输入关键字提交后切到搜索结果列表
///   （跨目录递归搜索），清空输入框自动切回浏览态。
/// - **错误页**：不直接展示原始异常，统一用简短文案 + 重试 / 返回上一页按钮。
/// 文件排序字段。
enum _SortField { defaultSort, name, size, modified }

class AsmrGayBrowserPage extends ConsumerStatefulWidget {
  const AsmrGayBrowserPage({
    super.key,
    this.initialPath = '/',
    this.isRoot = false,
  });

  /// 本页面对应的目录路径（Alist 风格，根目录为 '/'）。
  final String initialPath;

  /// 是否为根目录页面（由 [AlbumPage] 直接渲染）。
  ///
  /// `true`：系统返回交给外层 [MainScaffold]，错误页不显示"返回上一页"按钮。
  /// `false`：作为子目录页面 push 进 Navigator 栈，可被系统直接 pop。
  final bool isRoot;

  @override
  ConsumerState<AsmrGayBrowserPage> createState() =>
      _AsmrGayBrowserPageState();
}

class _AsmrGayBrowserPageState extends ConsumerState<AsmrGayBrowserPage> {
  // ─── 浏览态状态 ────────────────────────────────────────
  List<FileNode> _nodes = const [];
  int _currentPage = 0;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // ─── 搜索态状态 ────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchMode = false;
  String _searchKeywords = '';
  List<FileNode> _searchNodes = const [];
  int _searchPage = 0;
  int _searchTotal = 0;
  bool _isSearching = false;
  bool _isSearchingMore = false;
  String? _searchError;

  final ScrollController _scrollController = ScrollController();

  /// 排序字段
  _SortField _sortField = _SortField.defaultSort;

  /// 是否升序
  bool _sortAscending = true;

  /// 搜索范围：0=全部，1=仅文件夹，2=仅文件。
  ///
  /// 对应 Alist `/api/fs/search` 的 `scope` 参数，也用于浏览态本地过滤。
  int _searchScope = 0;

  /// 浏览态每页条目数
  static const int _perPage = 50;

  /// 搜索态每页条目数（Alist 搜索单次最多 100）
  static const int _searchPerPage = 100;

  /// 触底加载阈值（px）
  static const double _loadMoreThreshold = 240;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── 派生属性 ──────────────────────────────────────────

  String get _currentPath => widget.initialPath;

  /// 当前路径的层级片段（不含分隔符）。根目录返回空列表。
  List<String> get _pathSegments {
    if (_currentPath.isEmpty || _currentPath == '/') return const [];
    final trimmed = _currentPath.startsWith('/')
        ? _currentPath.substring(1)
        : _currentPath;
    return trimmed.split('/').where((s) => s.isNotEmpty).toList(growable: false);
  }

  bool get _hasMore => _nodes.length < _totalCount;
  bool get _searchHasMore => _searchNodes.length < _searchTotal;

  AsmrGaySiteApi? get _api {
    final api = ref.read(activeSiteApiProvider);
    return api is AsmrGaySiteApi ? api : null;
  }

  /// 当前激活的节点列表（搜索态优先，先过滤后排序）
  List<FileNode> get _activeNodes =>
      _isSearchMode ? _filteredSortedSearchNodes : _filteredSortedNodes;

  /// 浏览态：先按类型过滤，再排序。
  List<FileNode> get _filteredSortedNodes =>
      _sortNodes(_filterNodesByScope(_nodes));

  /// 搜索态：先按类型过滤，再排序。
  List<FileNode> get _filteredSortedSearchNodes =>
      _sortNodes(_filterNodesByScope(_searchNodes));

  /// 按当前 [_searchScope] 过滤节点。
  List<FileNode> _filterNodesByScope(List<FileNode> nodes) {
    switch (_searchScope) {
      case 1:
        return nodes.where((n) => n.isFolder).toList();
      case 2:
        return nodes.where((n) => !n.isFolder).toList();
      case 0:
      default:
        return nodes;
    }
  }

  /// 对节点列表按当前排序状态排序。
  ///
  /// 目录始终排在文件前面，然后再按所选字段排序。
  List<FileNode> _sortNodes(List<FileNode> nodes) {
    // 默认排序：不进行任何排序，保持接口返回顺序
    if (_sortField == _SortField.defaultSort) {
      return List<FileNode>.from(nodes);
    }
    final comparator = _nodeComparator;
    final factor = _sortAscending ? 1 : -1;
    return List<FileNode>.from(nodes)
      ..sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return comparator(a, b) * factor;
      });
  }

  int Function(FileNode a, FileNode b) get _nodeComparator {
    switch (_sortField) {
      case _SortField.defaultSort:
        return (_, __) => 0;
      case _SortField.size:
        return (a, b) => (a.size ?? 0).compareTo(b.size ?? 0);
      case _SortField.modified:
        return (a, b) => a.lastModified.compareTo(b.lastModified);
      case _SortField.name:
        return (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  }

  // ─── 滚动触底加载 ──────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreThreshold) return;

    if (_isSearchMode) {
      if (_isSearching || _isSearchingMore || !_searchHasMore) return;
      _loadMoreSearch();
      return;
    }
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _loadMore();
  }

  // ─── 浏览态加载 ────────────────────────────────────────

  Future<void> _loadInitial() async {
    final api = _api;
    if (api == null) {
      setState(() {
        _errorMessage = '当前站点不是 asmr.gay';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nodes = const [];
      _currentPage = 0;
      _totalCount = 0;
    });

    try {
      final result = await api.browseAsFileNodes(
        FsListRequest(path: _currentPath, page: 1, perPage: _perPage),
      );
      if (!mounted) return;
      setState(() {
        _nodes = result.items;
        _currentPage = 1;
        _totalCount = result.pagination.totalCount;
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('asmr.gay 浏览加载失败：$e\n$st');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    final api = _api;
    if (api == null || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await api.browseAsFileNodes(
        FsListRequest(path: _currentPath, page: nextPage, perPage: _perPage),
      );
      if (!mounted) return;
      setState(() {
        // 去重保护：Alist 偶发返回重复条目
        final existingKeys = _nodes.map((n) => n.remoteId).toSet();
        _nodes = [
          ..._nodes,
          ...result.items.where((n) => !existingKeys.contains(n.remoteId)),
        ];
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      debugPrint('asmr.gay 分页加载失败：$e');
    }
  }

  // ─── 搜索态加载 ────────────────────────────────────────

  Future<void> _startSearch(String keywords) async {
    final api = _api;
    if (api == null) return;

    _searchFocusNode.unfocus();

    setState(() {
      _isSearchMode = true;
      _searchKeywords = keywords;
      _isSearching = true;
      _searchError = null;
      _searchNodes = const [];
      _searchPage = 0;
      _searchTotal = 0;
    });

    try {
      final result = await api.searchAsFileNodes(
        FsSearchRequest(
          parent: '/',
          keywords: keywords,
          scope: _searchScope,
          page: 1,
          perPage: _searchPerPage,
        ),
      );
      if (!mounted) return;
      setState(() {
        _searchNodes = result.items;
        _searchPage = 1;
        _searchTotal = result.pagination.totalCount;
        _isSearching = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('asmr.gay 搜索失败：$e\n$st');
      setState(() {
        _isSearching = false;
        _searchError = e.toString();
      });
    }
  }

  Future<void> _loadMoreSearch() async {
    final api = _api;
    if (api == null || _isSearchingMore || !_searchHasMore) return;

    setState(() => _isSearchingMore = true);

    try {
      final nextPage = _searchPage + 1;
      final result = await api.searchAsFileNodes(
        FsSearchRequest(
          parent: '/',
          keywords: _searchKeywords,
          scope: _searchScope,
          page: nextPage,
          perPage: _searchPerPage,
        ),
      );
      if (!mounted) return;
      setState(() {
        final existingKeys = _searchNodes.map((n) => n.remoteId).toSet();
        _searchNodes = [
          ..._searchNodes,
          ...result.items.where((n) => !existingKeys.contains(n.remoteId)),
        ];
        _searchPage = nextPage;
        _isSearchingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearchingMore = false);
      debugPrint('asmr.gay 搜索分页失败：$e');
    }
  }

  /// 退出搜索态，回到浏览列表。
  void _exitSearchMode() {
    if (!_isSearchMode) return;
    setState(() {
      _isSearchMode = false;
      _searchKeywords = '';
      _searchNodes = const [];
      _searchPage = 0;
      _searchTotal = 0;
      _searchError = null;
      _isSearching = false;
      _isSearchingMore = false;
    });
    _searchController.clear();
  }

  // ─── 导航 ──────────────────────────────────────────────

  /// 进入子文件夹 —— push 新的 [AsmrGayBrowserPage]，
  /// 当前页面状态由 Navigator 自动保留。
  void _enterFolder(FileNode node) {
    final path = node.path;
    if (path == null || path.isEmpty || path == _currentPath) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AsmrGayBrowserPage(initialPath: path, isRoot: false),
      ),
    );
  }

  /// 面包屑跳转：根据层级片段索引 pop 多层。
  ///
  /// [segmentIndex] 对应 [_pathSegments] 的位置：
  /// - `-1`：回根目录
  /// - `i >= 0`：回到第 i 级目录
  ///
  /// 用 [Route.isFirst] 作为兜底：根目录页面由 go_router shell route
  /// 直接渲染（不在 push 栈上），popUntil 触到栈底必须停止，否则会把
  /// 路由栈底也弹掉，触发 "popped the last page off of the stack"。
  void _jumpToSegment(int segmentIndex) {
    final total = _pathSegments.length;
    final popCount = segmentIndex == -1
        ? total
        : (total - 1 - segmentIndex).clamp(0, total);
    if (popCount == 0) return;
    int popped = 0;
    Navigator.of(context).popUntil((route) {
      // 已 pop 够指定层级 → 停止
      if (popped >= popCount) return true;
      // 已到 Navigator 栈底（go_router shell route）→ 停止，避免过度 pop
      if (route.isFirst) return true;
      popped++;
      return false;
    });
  }

  Future<void> _refresh() async {
    if (_isSearchMode && _searchKeywords.isNotEmpty) {
      await _startSearch(_searchKeywords);
    } else {
      await _loadInitial();
    }
  }

  // ─── 构建 ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      // 子目录页面可被系统直接 pop；根目录页面交给 MainScaffold
      canPop: !widget.isRoot,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          bottom: false,
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final isSearch = _isSearchMode;
    final nodes = _activeNodes;
    final isLoading = isSearch ? _isSearching : _isLoading;
    final error = isSearch ? _searchError : _errorMessage;

    final showLoading = isLoading && nodes.isEmpty;
    final showError = error != null && nodes.isEmpty;
    final showEmpty = nodes.isEmpty && !isLoading && error == null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        key: ValueKey('asmr_gay_browser_$_currentPath'),
        controller: _scrollController,
        // 确保内容不足一屏时也能下拉刷新
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchHeader(theme)),
          if (!isSearch) SliverToBoxAdapter(child: _buildBreadcrumb(theme)),
          if (showLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (showError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorContent(theme, isSearch: isSearch),
            )
          else if (showEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyContent(theme, isSearch: isSearch),
            )
          else ...[
            FileNodeBrowser(
              currentNodes: nodes,
              work: null,
              source: NodeSource.asmrGay,
              config: const FileBrowserConfig(
                showDownloadBadge: false,
                showFolderStatus: false,
                subtitlesCopyMode: false,
                enableFolderLongPress: false,
                enableImagePreview: true,
                enableTextPreview: true,
                enableAudioContextMenu: false,
                showFolderEnterIcon: false,
                showFileMetaInfo: true,
              ),
              onEnterFolder: _enterFolder,
            ),
            SliverToBoxAdapter(child: _buildFooter(theme)),
          ],
        ],
      ),
    );
  }

  /// 顶部 AppBar 区域：与内容区背景一致，单行布局。
  ///
  /// 从左到右：返回/占位、搜索框、刷新、筛选下拉、排序下拉。
  /// 排序与正序/倒序合并在一个下拉菜单中。
  Widget _buildSearchHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final searchBg = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!widget.isRoot)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              tooltip: '返回上一页',
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '搜索 RJ 号 / 文件名',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade600,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          if (_isSearchMode) _exitSearchMode();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (text) {
                  if (text.isEmpty && _isSearchMode) {
                    _exitSearchMode();
                  }
                },
                onSubmitted: (kw) {
                  final trimmed = kw.trim();
                  if (trimmed.isEmpty) {
                    _exitSearchMode();
                  } else {
                    _startSearch(trimmed);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: '刷新',
            visualDensity: VisualDensity.compact,
            onPressed: _refresh,
          ),
          const SizedBox(width: 4),
          _buildScopeDropdown(theme),
          const SizedBox(width: 4),
          _buildSortDropdown(theme),
        ],
      ),
    );
  }

  /// 筛选下拉（全部 / 文件夹 / 文件），用于搜索 scope 与本地过滤。
  Widget _buildScopeDropdown(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    const items = [
      DropdownMenuItem(value: 0, child: Text('全部')),
      DropdownMenuItem(value: 1, child: Text('文件夹')),
      DropdownMenuItem(value: 2, child: Text('文件')),
    ];

    return Container(
      width: 76,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _searchScope,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    (item.child as Text).data!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: (value) {
            if (value == null || value == _searchScope) return;
            setState(() => _searchScope = value);
            if (_isSearchMode && _searchKeywords.isNotEmpty) {
              _startSearch(_searchKeywords);
            }
          },
        ),
      ),
    );
  }

  /// 排序下拉：同时选择字段与正序/倒序。
  Widget _buildSortDropdown(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final options = <(_SortField field, bool ascending, String label)>[
      (_SortField.defaultSort, true, '默认'),
      (_SortField.name, true, '名称 ↑'),
      (_SortField.name, false, '名称 ↓'),
      (_SortField.size, true, '大小 ↑'),
      (_SortField.size, false, '大小 ↓'),
      (_SortField.modified, true, '修改时间 ↑'),
      (_SortField.modified, false, '修改时间 ↓'),
    ];

    final currentValue = (_sortField, _sortAscending);

    String currentLabel;
    switch (_sortField) {
      case _SortField.defaultSort:
        currentLabel = '默认';
      case _SortField.name:
        currentLabel = '名称';
      case _SortField.size:
        currentLabel = '大小';
      case _SortField.modified:
        currentLabel = '修改时间';
    }
    if (_sortField != _SortField.defaultSort) {
      currentLabel += _sortAscending ? ' ↑' : ' ↓';
    }

    final items = options
        .map(
          (option) => DropdownMenuItem<( _SortField, bool)>(
            value: (option.$1, option.$2),
            child: Text(
              option.$3,
              style: TextStyle(
                fontSize: 13,
                color: (option.$1 == _sortField && option.$2 == _sortAscending)
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight:
                    (option.$1 == _sortField && option.$2 == _sortAscending)
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),
          ),
        )
        .toList();

    return Container(
      width: 100,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<(_SortField, bool)>(
          value: currentValue,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: (value) {
            if (value == null) return;
            final (field, ascending) = value;
            setState(() {
              _sortField = field;
              _sortAscending = ascending;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(ThemeData theme) {
    final paths = <String>['主页', ..._pathSegments];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: BreadcrumbBar(
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        padding: EdgeInsets.zero,
        paths: paths,
        onPathTap: (index) {
          // paths[0] = '主页' → 回根目录
          // paths[i] (i>=1) = _pathSegments[i-1]
          if (index == 0) {
            _jumpToSegment(-1);
          } else {
            _jumpToSegment(index - 1);
          }
        },
        onHomeTap: () => _jumpToSegment(-1),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final isSearch = _isSearchMode;
    final loadingMore = isSearch ? _isSearchingMore : _isLoadingMore;
    final hasMore = isSearch ? _searchHasMore : _hasMore;
    final loadedCount = _activeNodes.length;
    final totalCount = isSearch ? _searchTotal : _totalCount;

    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: isSearch ? _loadMoreSearch : _loadMore,
            icon: const Icon(Icons.expand_more, size: 18),
            label: const Text('加载更多'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '已加载 $loadedCount / $totalCount 项',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  /// 错误态内容（不含搜索框 header，由 [_buildBody] 统一拼装）。
  ///
  /// 不直接展示原始异常，统一用简短文案 + 副文案，原始错误通过
  /// [debugPrint] 输出到控制台。
  Widget _buildErrorContent(ThemeData theme, {required bool isSearch}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? '搜索失败' : '加载失败',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查网络连接后重试',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isRoot) ...[
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('返回上一页'),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 空态内容（不含搜索框 header，由 [_buildBody] 统一拼装）。
  Widget _buildEmptyContent(ThemeData theme, {required bool isSearch}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? '没有找到相关内容' : '该目录为空',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('刷新'),
            ),
          ],
        ],
      ),
    );
  }
}
