import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import '../../routes/app_routes.dart';
import '../../../features/album/data/model/work.dart';
import '../../utils/data/colors_util.dart';

class SmartColorCard extends StatefulWidget {
  final Work work;
  final double? width;
  final double borderRadius;

  const SmartColorCard({
    super.key,
    required this.work,
    this.width,
    this.borderRadius = 14,
  });

  @override
  State<SmartColorCard> createState() => _SmartColorCardState();
}

class _SmartColorCardState extends State<SmartColorCard> {
  // 静态缓存，避免在列表滚动时重复提取同一个 Work 的颜色
  static final Map<String, Color> _colorCache = {};
  Color? _dominantColor;
  bool _isLoadingColor = false;

  @override
  void initState() {
    super.initState();
    _initColor();
  }

  void _initColor() {
    final key = widget.work.id?.toString() ?? widget.work.title ?? '';

    if (_colorCache.containsKey(key)) {
      _dominantColor = _colorCache[key];
    } else {
      // 延迟提取：避开页面入场动画或列表快速滑动时的首帧压力
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _loadDominantColor(key);
        }
      });
    }
  }

  Future<void> _loadDominantColor(String key) async {
    if (_isLoadingColor) return;
    _isLoadingColor = true;

    final url = widget.work.mainCoverUrl ?? "";
    if (url.isEmpty) return;

    final color = await ColorUtils.getMainColors(url);
    if (mounted) {
      setState(() {
        _dominantColor = color;
        _colorCache[key] = color;
      });
    }
    _isLoadingColor = false;
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 240.0;
    final imageHeight = cardWidth * 3 / 4;
    const bottomHeight = 60.0;
    // 使用占位色，直到颜色提取完成
    final baseColor = _dominantColor ?? Colors.grey.shade800;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        context.push(AppRoutes.detail, extra: {'work': widget.work});
      },
      child: RepaintBoundary( // 关键：隔离重绘区域，baseColor 变化时不触发父级重绘
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 紧凑布局
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: widget.work.heroTag ?? widget.work.id.toString(),
                child: SizedBox(
                  width: cardWidth,
                  height: imageHeight,
                  child: SimpleExtendedImage(
                    widget.work.mainCoverUrl ?? "",
                  ),
                ),
              ),
              AnimatedContainer( // 使用动画容器，让颜色切换更平滑
                duration: const Duration(milliseconds: 300),
                width: cardWidth,
                height: bottomHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: baseColor,
                child: Text(
                  widget.work.title ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}