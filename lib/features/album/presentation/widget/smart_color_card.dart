import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class SmartColorCard extends StatefulWidget {
  final String imageUrl;
  final String title;

  // 仅保留 width，由父组件决定
  final double width;
  final double borderRadius;

  const SmartColorCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.width,
    this.borderRadius = 14,
  });

  @override
  State<SmartColorCard> createState() => _SmartColorCardState();
}

class _SmartColorCardState extends State<SmartColorCard> {
  Color? dominantColor;
  final double bottomHeight = 60.0; // 底部文字固定高度
  final double imageAspectRatio = 4 / 3; // 图片原始比例

  @override
  void initState() {
    super.initState();
    _extractDominantColor();
  }

  ImageProvider _getImageProvider() {
    final url = widget.imageUrl;
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return NetworkImage(url);
    } else {
      return AssetImage(url);
    }
  }

  Future<void> _extractDominantColor() async {
    final provider = _getImageProvider();
    final palette = await PaletteGenerator.fromImageProvider(
      provider,
      maximumColorCount: 18,
      size: Size(widget.width, widget.width / imageAspectRatio + bottomHeight),
    );

    setState(() {
      dominantColor = palette.dominantColor?.color ?? Colors.grey.shade300;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = widget.width / imageAspectRatio; // 根据比例计算
    final totalHeight = imageHeight + bottomHeight;
    final bottomColor = dominantColor ?? Colors.grey.shade300;

    return SizedBox(
      width: widget.width,
      height: totalHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片区域
            SizedBox(
              width: widget.width,
              height: imageHeight,
              child: Image(
                image: _getImageProvider(),
                fit: BoxFit.cover,
              ),
            ),
            // 底部文字，只显示标题，可占两行
            Container(
              width: widget.width,
              height: bottomHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: bottomColor,
              child: Text(
                widget.title,
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
    );
  }
}
