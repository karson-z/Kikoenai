import 'package:flutter/material.dart';

/// 文件浏览编辑模式的底部操作栏。
class FileBrowserEditBar extends StatelessWidget {
  const FileBrowserEditBar({
    super.key,
    required this.selectedCount,
    required this.allSelected,
    required this.canParse,
    required this.canPlay,
    required this.canExclude,
    required this.onToggleAll,
    required this.onParse,
    required this.onPlay,
    required this.onExclude,
    required this.onDone,
  });

  final int selectedCount;
  final bool allSelected;
  final bool canParse;
  final bool canPlay;
  final bool canExclude;
  final VoidCallback onToggleAll;
  final VoidCallback onParse;
  final VoidCallback onPlay;
  final VoidCallback onExclude;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _Action(
                icon: allSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                label: allSelected ? '取消全选' : '全选',
                onPressed: onToggleAll,
              ),
              _Action(
                icon: Icons.manage_search,
                label: '加入解析',
                onPressed: canParse ? onParse : null,
              ),
              _Action(
                icon: Icons.playlist_add,
                label: '加入播放',
                onPressed: canPlay ? onPlay : null,
              ),
              if (canExclude)
                _Action(
                  icon: Icons.visibility_off_outlined,
                  label: '排除',
                  onPressed: selectedCount == 0 ? null : onExclude,
                ),
              _Action(icon: Icons.done, label: '完成', onPressed: onDone),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).disabledColor;
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
