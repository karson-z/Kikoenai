import 'package:flutter/material.dart';
import 'package:kikoenai/core/constants/app_images.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingIndicator extends StatelessWidget {
  /// Lottie 动画资源路径；为 null 时使用默认加载动画
  /// （[Assets.animation.animation1766645713509]）。
  ///
  /// 保持 String 类型以兼容 const 构造调用；默认值在运行时从 flutter_gen
  /// 生成的 [Assets] 常量解析，避免硬编码路径。
  final String? assetPath;
  final double? size;
  final String? message;
  final BoxFit fit;

  const LottieLoadingIndicator({
    super.key,
    this.assetPath,
    this.size,
    this.message,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final double displaySize = size ?? 60.0;
    final String effectiveAssetPath =
        assetPath ?? Assets.animation.animation1766645713509.path;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: displaySize, // 使用处理后的非空尺寸
            width: displaySize,
            child: Lottie.asset(
              effectiveAssetPath,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(' Lottie Error [$effectiveAssetPath]: $error');
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