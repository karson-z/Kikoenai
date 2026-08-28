import 'package:flutter/material.dart';

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
          Expanded(child: _buildSearchField(context)),
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

  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: '搜索标题 / RJ / 社团',
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
      ),
    );
  }
}
