import 'package:flutter/material.dart';

class EditableCheckButton extends StatelessWidget {
  final bool editing;
  final bool selected;
  final bool isExclude; // 三态之一：排除
  final String label;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final Color? activeColor; // 正常选中颜色
  final Color? excludeColor; // 排除颜色

  const EditableCheckButton({
    super.key,
    required this.editing,
    required this.selected,
    required this.label,
    required this.isExclude,
    this.onChanged,
    this.onTap,
    this.activeColor,
    this.excludeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color colorActive = activeColor ?? theme.colorScheme.primary;
    final Color colorExclude = excludeColor ?? Colors.red;
    const Color colorInactive = Colors.grey;

    // 三态染色逻辑
    final Color displayColor = selected
        ? (isExclude ? colorExclude : colorActive)
        : colorInactive;

    final TextStyle textStyle = TextStyle(
      color: displayColor,
      fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (editing)
              SizedBox(
                height: 15,
                child: Transform.scale(
                  scale: 0.7,
                  child: Checkbox(
                    value: selected,                // 仅反映是否“被选中”
                    onChanged: (v) => onChanged?.call(v ?? false),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 12,
                    activeColor: displayColor,     // 勾选颜色走显示颜色
                    side: BorderSide(
                      color: displayColor,         // 边框颜色也必须跟颜色一致（排除则为红）
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(label, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}
