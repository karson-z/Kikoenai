import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../routes/app_routes.dart';
import '../../../features/album/data/model/work.dart';

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
            _colorCache[key] = color; // 缓存
          });
        }
      });
    }
  }

  Future<Color> _extractDominantColor() async {
    final url = widget.work.thumbnailCoverUrl ?? "";
    final provider = url.startsWith("http")
        ? CachedNetworkImageProvider(url)
        : AssetImage(url) as ImageProvider;

    final cardWidth = widget.width ?? 240;
    const bottomHeight = 60.0;

    final palette = await PaletteGenerator.fromImageProvider(
      provider,
      maximumColorCount: 18,
      size: Size(cardWidth, cardWidth * 3 / 4 + bottomHeight),
    );

    return palette.dominantColor?.color ?? Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 240.0;
    final imageHeight = cardWidth * 3 / 4;
    const bottomHeight = 60.0;
    final totalHeight = imageHeight + bottomHeight;

    final baseColor = _dominantColor ?? Colors.grey.shade300;

    final placeholderDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [baseColor.withAlpha(50), baseColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // 卡片点击逻辑：跳转详情页，携带 work 对象
        context.push(AppRoutes.detail,extra: {'work': widget.work});
      },
      child: SizedBox(
        width: cardWidth,
        height: totalHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(tag: widget.work.heroTag!, child: SizedBox(
                width: cardWidth,
                height: imageHeight,
                child: CachedNetworkImage(
                  imageUrl: widget.work.thumbnailCoverUrl ?? "",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: placeholderDecoration,
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: placeholderDecoration,
                    child: const Icon(Icons.error, color: Colors.white),
                  ),
                ),
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
