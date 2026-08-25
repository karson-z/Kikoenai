import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';

import '../../utils/data/colors_util.dart';

class SmartColorCard extends StatefulWidget {
  final int id;
  final String? title;
  final String? mainCoverUrl;
  final String heroTag;
  final VoidCallback? onTap;
  final double? width;
  final double borderRadius;

  const SmartColorCard({
    super.key,
    required this.id,
    this.title,
    this.mainCoverUrl,
    required this.heroTag,
    this.onTap,
    this.width,
    this.borderRadius = 14,
  });

  @override
  State<SmartColorCard> createState() => _SmartColorCardState();
}

class _SmartColorCardState extends State<SmartColorCard> {
  static final Map<String, Color> _colorCache = {};
  Color? _dominantColor;
  bool _isLoadingColor = false;

  @override
  void initState() {
    super.initState();
    _initColor();
  }

  @override
  void didUpdateWidget(covariant SmartColorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.mainCoverUrl != widget.mainCoverUrl) {
      _dominantColor = null;
      _isLoadingColor = false;
      _initColor();
    }
  }

  void _initColor() {
    final key = widget.id.toString();

    if (_colorCache.containsKey(key)) {
      _dominantColor = _colorCache[key];
    } else {
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

    final url = widget.mainCoverUrl ?? '';
    if (url.isEmpty) {
      _isLoadingColor = false;
      return;
    }

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
    final baseColor = _dominantColor ?? Colors.grey.shade800;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: widget.heroTag,
                child: SizedBox(
                  width: cardWidth,
                  height: imageHeight,
                  child: SimpleExtendedImage(widget.mainCoverUrl ?? ''),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: cardWidth,
                height: bottomHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: baseColor,
                child: Text(
                  widget.title ?? '',
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
