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
  static final Map<String, Color> _colorCache = {};
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    final key = widget.work.id?.toString() ?? widget.work.title ?? '';
    if (_colorCache.containsKey(key)) {
      _dominantColor = _colorCache[key];
    } else {
      _extractDominantColor().then((color) {
        if (mounted) {
          setState(() {
            _dominantColor = color;
            _colorCache[key] = color ?? Colors.grey.shade600; // 缓存
          });
        }
      });
    }
  }

  Future<Color?> _extractDominantColor() async {
    final url = widget.work.mainCoverUrl ?? "";
    final colorData = ColorUtils.getMainColors(url);
    final dominantColor = (await colorData)['dominant'];
    return dominantColor;
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 240.0;
    final imageHeight = cardWidth * 3 / 4;
    const bottomHeight = 60.0;
    final baseColor = _dominantColor ?? Colors.grey.shade300;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // 卡片点击逻辑：跳转详情页，携带 work 对象
        context.push(AppRoutes.detail,extra: {'work': widget.work});
      },
      child: SizedBox.expand(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(tag: widget.work.heroTag!, child: SizedBox(
                width: cardWidth,
                height: imageHeight,
                child: SimpleExtendedImage(
                  widget.work.mainCoverUrl ?? "",
                )
              )),
              Container(
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
