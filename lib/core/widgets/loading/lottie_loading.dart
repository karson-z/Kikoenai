import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingIndicator extends StatelessWidget {
  /// Lottie 动画文件的路径
  final String assetPath;
  final double size;
  final String? message;
  final BoxFit fit;

  const LottieLoadingIndicator({
    super.key,
    this.assetPath = 'assets/animation/Animation - 1766645713509.json',
    this.size = 60.0,
    this.message,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: Lottie.asset(
              assetPath,
              fit: fit,
              // --------------------------------------------------------
              // 核心修复：添加 errorBuilder
              // 当 Lottie 文件损坏或解析失败时，拦截错误，防止红屏崩溃
              // --------------------------------------------------------
              errorBuilder: (context, error, stackTrace) {
                // 在控制台打印错误，方便你知道是哪个文件坏了
                debugPrint('❌ Lottie Error [$assetPath]: $error');

                // 返回一个简单的图标代替动画
                return Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400,
                  size: size * 0.5,
                );
              },
              // 可选：添加 frameBuilder 避免加载时的闪烁
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