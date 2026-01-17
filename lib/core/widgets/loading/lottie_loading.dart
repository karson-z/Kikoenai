import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingIndicator extends StatelessWidget {
  /// Lottie 动画文件的路径
  final String assetPath;
  final double? size;
  final String? message;
  final BoxFit fit;

  const LottieLoadingIndicator({
    super.key,
    this.assetPath = 'assets/animation/Animation - 1766645713509.json',
    this.size,
    this.message,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final double displaySize = size ?? 60.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: displaySize, // 使用处理后的非空尺寸
            width: displaySize,
            child: Lottie.asset(
              assetPath,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(' Lottie Error [$assetPath]: $error');
                return Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400,
                  size: displaySize * 0.5,
                );
              },
              frameBuilder: (context, child, composition) {
                if (composition != null) {
                  return child;
                } else {
                  return const SizedBox();
                }
              },
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}