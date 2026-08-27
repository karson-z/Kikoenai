import 'package:flutter/material.dart';

import '../model/cloud_drive_mode.dart';

class CloudDriveToolbar extends StatelessWidget {
  const CloudDriveToolbar({
    super.key,
    required this.isRoot,
    required this.isLoading,
    required this.usesRemoteSearch,
    required this.searchController,
    required this.searchFocusNode,
    required this.scope,
    required this.sort,
    required this.onBack,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onScopeChanged,
    required this.onSortChanged,
    this.onManageSource,
    this.manageTooltip = '来源设置',
  });

  final bool isRoot;
  final bool isLoading;
  final bool usesRemoteSearch;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final CloudDriveScope scope;
  final CloudDriveSort sort;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final ValueChanged<CloudDriveScope> onScopeChanged;
  final ValueChanged<CloudDriveSort> onSortChanged;
  final VoidCallback? onManageSource;
  final String manageTooltip;

  @override
  Widget build(BuildContext context) {
    final leading = isRoot
        ? null
        : _buildIconButton(
            icon: Icons.arrow_back,
            tooltip: '返回上一级',
            onPressed: onBack,
          );
    final manage = isRoot && onManageSource != null
        ? _buildIconButton(
            icon: Icons.settings_outlined,
            tooltip: manageTooltip,
            onPressed: onManageSource,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (leading != null) leading,
          Expanded(child: _buildSearchField(context)),
          if (manage != null) manage,
          _buildIconButton(
            icon: Icons.refresh,
            tooltip: '刷新',
            onPressed: isLoading ? null : onRefresh,
          ),
          SizedBox(
            width: 32,
            height: 36,
            child: PopupMenuButton<CloudDriveScope>(
              tooltip: '筛选',
              padding: EdgeInsets.zero,
              iconSize: 20,
              initialValue: scope,
              icon: Icon(
                Icons.filter_alt_outlined,
                color: scope == CloudDriveScope.all
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
              onSelected: onScopeChanged,
              itemBuilder: (context) => CloudDriveScope.values
                  .map(
                    (value) =>
                        PopupMenuItem(value: value, child: Text(value.label)),
                  )
                  .toList(),
            ),
          ),
          SizedBox(
            width: 32,
            height: 36,
            child: PopupMenuButton<CloudDriveSort>(
              tooltip: '排序',
              padding: EdgeInsets.zero,
              iconSize: 20,
              initialValue: sort,
              icon: Icon(
                Icons.sort,
                color: sort == CloudDriveSort.defaultSort
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
              onSelected: onSortChanged,
              itemBuilder: (context) => CloudDriveSort.values
                  .map(
                    (value) =>
                        PopupMenuItem(value: value, child: Text(value.label)),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.expand(),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        textInputAction: usesRemoteSearch
            ? TextInputAction.search
            : TextInputAction.done,
        decoration: InputDecoration(
          hintText: usesRemoteSearch ? '搜索全部目录' : '搜索当前目录',
          prefixIcon: const Icon(Icons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.expand(),
                    tooltip: '清空搜索',
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClearSearch,
                  ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 36,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF242426) : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: onSearchChanged,
        onSubmitted: onSearchSubmitted,
      ),
    );
  }
}
