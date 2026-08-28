import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/toolbar_search_field.dart';

class LocalMediaToolbar extends StatelessWidget {
  const LocalMediaToolbar({
    super.key,
    required this.isRoot,
    required this.isScanning,
    required this.searchController,
    required this.searchFocusNode,
    required this.onBack,
    required this.onManagePaths,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSort,
  });

  final bool isRoot;
  final bool isScanning;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onBack;
  final VoidCallback onManagePaths;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final leading = isRoot
        ? null
        : _buildIconButton(
            icon: Icons.arrow_back,
            tooltip: '返回上一级',
            onPressed: onBack,
          );
    final manage = isRoot
        ? _buildIconButton(
            icon: Icons.folder_copy_outlined,
            tooltip: '管理路径',
            onPressed: onManagePaths,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (leading != null) leading,
          Expanded(
            child: ToolbarSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              hintText: '搜索当前目录',
              onChanged: onSearchChanged,
              onClear: onClearSearch,
            ),
          ),
          if (manage != null) manage,
          _buildSyncButton(),
          _buildIconButton(icon: Icons.sort, tooltip: '排序', onPressed: onSort),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    if (!isScanning) {
      return _buildIconButton(
        icon: Icons.sync,
        tooltip: '同步媒体库',
        onPressed: onRefresh,
      );
    }

    return const SizedBox(
      width: 32,
      height: 36,
      child: Center(
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
}
