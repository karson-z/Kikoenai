import 'package:flutter/material.dart';

import '../../core/model/search_tag.dart';
import '../category/presentation/viewmodel/state/category_ui_state.dart';

class AdvancedSearchPage extends StatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  State<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage> {
  // 核心状态
  late CategoryUiState _state;
  final TextEditingController _searchController = TextEditingController();

  // 模拟数据：分类与选项
  final Map<String, List<String>> _filterData = {
    'tag': ['日常', '战斗', '魔法', '校园', '治愈', '科幻', '历史'],
    'author': ['作者A', '作者B', '作者C', 'UserX', 'StudioY'],
    'circle': ['社团Alpha', '社团Beta', '社团Gamma'],
    'rating': ['全年龄', 'R15', 'R18'],
  };

  // 左侧导航对应的 key
  final List<String> _categoryKeys = ['tag', 'author', 'circle', 'rating'];
  final List<String> _categoryLabels = ['标签', '作者', '社团', '分级'];

  @override
  void initState() {
    super.initState();
    _state = const CategoryUiState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 逻辑处理区域 ---

  /// 处理标签点击的三态逻辑
  /// 1. 不在列表中 -> 添加为包含 (Include)
  /// 2. 已在列表中且为包含 -> 改为排除 (Exclude)
  /// 3. 已在列表中且为排除 -> 移除 (Cancel)
  void _toggleTag(String type, String name) {
    List<SearchTag> newSelected = List.from(_state.selected);

    // 查找是否存在同类型同名的标签（忽略 isExclude 状态）
    final existingIndex = newSelected.indexWhere((t) => t.type == type && t.name == name);

    if (existingIndex == -1) {
      // 状态 1 -> 2: 选中 (Include)
      newSelected.add(SearchTag(type, name, false));
    } else {
      final currentTag = newSelected[existingIndex];
      if (!currentTag.isExclude) {
        // 状态 2 -> 3: 排除 (Exclude)
        newSelected[existingIndex] = SearchTag(type, name, true);
      } else {
        // 状态 3 -> 1: 取消 (Remove)
        newSelected.removeAt(existingIndex);
      }
    }

    setState(() {
      _state = _state.copyWith(selected: newSelected);
    });
  }

  /// 执行搜索
  void _performSearch() {
    // 1. 获取纯文本
    String textQuery = _state.keyword ?? "";

    // 2. 获取高级标签 Query string
    String advancedQuery = _state.selected.map((e) => e.toString()).join(" ");

    // 3. 拼接最终 URL 或参数
    String finalQuery = "$textQuery $advancedQuery".trim();

    print("正在搜索 URL Query: $finalQuery");
    // TODO: 这里调用你的 API 或跳转结果页
  }

  // --- UI 构建区域 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        actions: [
          IconButton(
            icon: Icon(_state.isFilterOpen ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _state = _state.copyWith(isFilterOpen: !_state.isFilterOpen);
              });
            },
          ),
          TextButton(
              onPressed: _performSearch,
              child: const Text("搜索")
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 这里的 Chips 展示区，让用户知道当前选中了什么，即使在筛选面板关闭时
          if (_state.selected.isNotEmpty) _buildSelectedTagsBar(),

          // 2. 主体内容：筛选面板 或 搜索结果占位
          Expanded(
            child: _state.isFilterOpen
                ? _buildAdvancedFilterPanel()
                : _buildSearchResultsPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: '输入关键字...',
        border: InputBorder.none,
      ),
      onChanged: (val) {
        setState(() {
          _state = _state.copyWith(keyword: val);
        });
      },
      onSubmitted: (_) => _performSearch(),
    );
  }

  Widget _buildSelectedTagsBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _state.selected.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = _state.selected[index];
          return Chip(
            label: Text(tag.name),
            avatar: Icon(
              tag.isExclude ? Icons.remove_circle : Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            backgroundColor: tag.isExclude ? Colors.red.shade400 : Colors.blue.shade400,
            labelStyle: const TextStyle(color: Colors.white),
            deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
            onDeleted: () {
              _toggleTag(tag.type, tag.name); // 这里的逻辑可能需要改为直接移除，看需求
              // 如果点击 X 是直接移除：
              /*
               final newList = List<SearchTag>.from(_state.selected)..removeAt(index);
               setState(() => _state = _state.copyWith(selected: newList));
               */
            },
          );
        },
      ),
    );
  }

  Widget _buildAdvancedFilterPanel() {
    return Row(
      children: [
        // 左侧：分类导航
        NavigationRail(
          selectedIndex: _state.selectedFilterIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _state = _state.copyWith(selectedFilterIndex: index);
            });
          },
          labelType: NavigationRailLabelType.all,
          destinations: _categoryLabels
              .map((label) => NavigationRailDestination(
            icon: const SizedBox.shrink(), // 可以加图标
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label),
            ),
          ))
              .toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // 右侧：选项网格
        Expanded(
          child: Column(
            children: [
              // 面板内的本地搜索（可选）
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '在该分类下筛选...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _state = _state.copyWith(localSearchKeyword: val);
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildOptionsGrid(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsGrid() {
    final currentTypeKey = _categoryKeys[_state.selectedFilterIndex];
    final allOptions = _filterData[currentTypeKey] ?? [];

    // 简单的本地过滤逻辑
    final displayOptions = _state.localSearchKeyword.isEmpty
        ? allOptions
        : allOptions.where((e) => e.contains(_state.localSearchKeyword)).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 根据屏幕宽度调整
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: displayOptions.length,
      itemBuilder: (context, index) {
        final name = displayOptions[index];
        return _buildThreeStateButton(currentTypeKey, name);
      },
    );
  }

  /// 构建支持三态点击的按钮
  Widget _buildThreeStateButton(String type, String name) {
    // 检查当前状态
    // find tag ignoring isExclude first to see if it exists
    final existingIndex = _state.selected.indexWhere((t) => t.type == type && t.name == name);

    bool isSelected = existingIndex != -1;
    bool isExclude = false;

    if (isSelected) {
      isExclude = _state.selected[existingIndex].isExclude;
    }

    // 定义样式
    Color backgroundColor = Colors.grey.shade200;
    Color textColor = Colors.black87;
    IconData? icon;

    if (isSelected) {
      if (isExclude) {
        // 排除模式 (红色)
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.block;
      } else {
        // 选中模式 (蓝色/绿色)
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        icon = Icons.check;
      }
    }

    return InkWell(
      onTap: () => _toggleTag(type, name),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: textColor.withOpacity(0.5)) : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              name,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "纯文本: ${_state.keyword ?? '无'}\n"
                "标签筛选: ${_state.selected.map((e) => e.toString()).join(', ')}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}