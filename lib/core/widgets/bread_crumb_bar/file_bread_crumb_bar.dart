import 'package:flutter/material.dart';

class BreadcrumbBar extends StatefulWidget {
  final List<String> paths;
  final ValueChanged<int> onPathTap;
  final VoidCallback onHomeTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;

  const BreadcrumbBar({
    super.key,
    required this.paths,
    required this.onPathTap,
    required this.onHomeTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
  });

  @override
  State<BreadcrumbBar> createState() => _BreadcrumbBarState();
}

class _BreadcrumbBarState extends State<BreadcrumbBar> {
  static const int _visiblePathCount = 2;

  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant BreadcrumbBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当路径数量发生变化（通常是进入了更深层级）时，触发滚动
    if (widget.paths.length != oldWidget.paths.length) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final firstVisiblePathIndex = widget.paths.length > _visiblePathCount
        ? widget.paths.length - _visiblePathCount
        : 0;
    final defaultBgColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.36 : 0.62,
    );
    final defaultBorderColor = colorScheme.outlineVariant.withValues(
      alpha: 0.75,
    );

    return Container(
      width: double.infinity,
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBgColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!)
            : Border.all(color: defaultBorderColor),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Tooltip(
              message: '返回根目录',
              child: InkWell(
                key: const ValueKey('breadcrumb-home'),
                onTap: widget.onHomeTap,
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.square(
                  dimension: 32,
                  child: Icon(
                    Icons.home_outlined,
                    size: 18,
                    color: widget.paths.isEmpty
                        ? colorScheme.onSurface
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
            if (firstVisiblePathIndex > 0) ...[
              _BreadcrumbSeparator(color: colorScheme.onSurfaceVariant),
              PopupMenuButton<int>(
                key: const ValueKey('breadcrumb-overflow'),
                tooltip: '查看上级路径',
                position: PopupMenuPosition.under,
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
                padding: EdgeInsets.zero,
                onSelected: widget.onPathTap,
                itemBuilder: (context) => [
                  for (var index = 0; index < firstVisiblePathIndex; index++)
                    PopupMenuItem<int>(
                      value: index,
                      child: Text(
                        widget.paths[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                child: SizedBox.square(
                  dimension: 32,
                  child: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            for (
              var index = firstVisiblePathIndex;
              index < widget.paths.length;
              index++
            ) ...[
              _BreadcrumbSeparator(color: colorScheme.onSurfaceVariant),
              _BreadcrumbPath(
                key: ValueKey('breadcrumb-path-$index'),
                label: widget.paths[index],
                isCurrent: index == widget.paths.length - 1,
                onPressed: () => widget.onPathTap(index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.chevron_right, size: 16, color: color),
    );
  }
}

class _BreadcrumbPath extends StatelessWidget {
  const _BreadcrumbPath({
    super.key,
    required this.label,
    required this.isCurrent,
    required this.onPressed,
  });

  final String label;
  final bool isCurrent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isCurrent
            ? theme.colorScheme.onSurface
            : theme.colorScheme.primary,
        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
      ),
    );

    if (isCurrent) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: text,
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: text,
      ),
    );
  }
}
