import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:go_router/go_router.dart';

class ExtendedImagePreviewPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ExtendedImagePreviewPage({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ExtendedImagePreviewPage> createState() => _ExtendedImagePreviewPageState();
}

class _ExtendedImagePreviewPageState extends State<ExtendedImagePreviewPage> {
  late int _currentIndex;
  final GlobalKey<ExtendedImageSlidePageState> _slidePageKey = GlobalKey<ExtendedImageSlidePageState>();
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ExtendedImageSlidePage(
            key: _slidePageKey,
            slideType: SlideType.wholePage,
            slidePageBackgroundHandler: (Offset offset, Size pageSize) {
              double dy = offset.dy;
              if (dy < 0) dy = -dy;
              double opacity = 1 - dy / (pageSize.height / 2.0);
              if (opacity < 0) opacity = 0;
              if (opacity > 1) opacity = 1;
              return Colors.black.withOpacity(opacity);
            },

            // 监听状态，隐藏按钮
            onSlidingPage: (state) {
              if (_isSliding != state.isSliding) {
                setState(() {
                  _isSliding = state.isSliding;
                });
              }
            },

            slideEndHandler: (Offset offset, {ExtendedImageSlidePageState? state, ScaleEndDetails? details}) {
              return null;
            },

            child: _buildPageView(),
          ),

          // 关闭按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSliding ? 0.0 : 1.0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () {
                  context.pop();
                },
              ),
            ),
          ),

          // 页码
          Positioned(
            bottom: 30,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSliding ? 0.0 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentIndex + 1} / ${widget.imageUrls.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return ExtendedImageGesturePageView.builder(
      controller: ExtendedPageController(
        initialPage: widget.initialIndex,
      ),
      itemCount: widget.imageUrls.length,
      onPageChanged: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        final String url = widget.imageUrls[index];
        return ExtendedImage.network(
          url,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.gesture,
          // 确保 enableSlideOutPage 为 true (默认就是 true)
          enableSlideOutPage: true,
          initGestureConfigHandler: (state) {
            return GestureConfig(
              minScale: 0.9,
              animationMinScale: 0.7,
              maxScale: 3.0,
              animationMaxScale: 3.5,
              speed: 1.0,
              inertialSpeed: 100.0,
              initialScale: 1.0,
              inPageView: true,
            );
          },
        );
      },
    );
  }
}