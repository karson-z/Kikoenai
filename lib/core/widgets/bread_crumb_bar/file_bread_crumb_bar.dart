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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50];
    final defaultBorderColor = isDark ? Colors.white10 : Colors.black12;

    return Container(
      width: double.infinity,
      padding: widget.padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBgColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!)
            : Border.all(color: defaultBorderColor),
      ),
      child: SingleChildScrollView(
        controller: _scrollController, // 绑定 ScrollController
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: widget.onHomeTap,
              borderRadius: BorderRadius.circular(4),
              child: Icon(
                Icons.home_outlined,
                size: 18,
                color: widget.paths.isEmpty ? Colors.blue : Colors.grey[500],
              ),
            ),
            for (int i = 0; i < widget.paths.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ),
              InkWell(
                onTap: () => widget.onPathTap(i),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  widget.paths[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: i == widget.paths.length - 1
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.blue,
                    fontWeight: i == widget.paths.length - 1
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}