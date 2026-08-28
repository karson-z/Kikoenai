import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/common/toolbar_search_field.dart';

class DlLibraryToolbar extends StatelessWidget {
  const DlLibraryToolbar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.isEditing,
    required this.hasWorks,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleEditing,
    required this.onClearAll,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isEditing;
  final bool hasWorks;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleEditing;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: ToolbarSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              hintText: '搜索标题 / RJ / 社团',
              onChanged: onSearchChanged,
              onClear: onClearSearch,
            ),
          ),
          if (isEditing)
            _buildIconButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: '全部清空',
              color: Theme.of(context).colorScheme.error,
              onPressed: hasWorks ? onClearAll : null,
            ),
          _buildIconButton(
            icon: isEditing ? Icons.check_rounded : Icons.edit_outlined,
            tooltip: isEditing ? '完成编辑' : '编辑作品',
            onPressed: hasWorks || isEditing ? onToggleEditing : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.expand(),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
