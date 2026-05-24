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

    // 强化视觉对比度，防止与 Scaffold 页面色融为一体
    final defaultBgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey[100];
    final defaultBorderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBgColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16), // 使用更精致的圆角弧度
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!)
            : Border.all(color: defaultBorderColor),
      ),
      child: IconTheme(
        // 显式规范内部图标主题，确保在 AppBar 等特殊环境下颜色不被系统强行覆盖
        data: IconThemeData(color: isDark ? Colors.white70 : Colors.black54),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(), // 开启干净不溢出的非回弹物理滚动
          child: Row(
            mainAxisSize: MainAxisSize.min, // 严格限制 Row 宽度仅包裹实际内容
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 根路径主页图标
              InkWell(
                onTap: widget.onHomeTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.home_rounded, // 升级为极具科技感的圆角图标
                    size: 18,
                    color: widget.paths.isEmpty
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),

              // 循环渲染相对层级面包屑数组
              for (int i = 0; i < widget.paths.length; i++) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                ),

                // 精准鉴权可点击项
                InkWell(
                  onTap: i == widget.paths.length - 1 ? null : () => widget.onPathTap(i),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    // 补充合理的内边距，扩大点击热区的同时，避免文字紧贴 chevron 图标
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      widget.paths[i],
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        color: i == widget.paths.length - 1
                            ? (isDark ? Colors.white : Colors.black87)
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: i == widget.paths.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}