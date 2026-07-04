import 'dart:io';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';

import '../../constants/app_images.dart';

class SimpleExtendedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final String placeholder;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget? replacement;
  final BoxFit? fit;
  final int? cacheWidth;
  final double? loadingSize;
  final double? origAspectRatio;

  const SimpleExtendedImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.placeholder = placeholderImage,
    this.replacement,
    this.fit,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.loadingSize,
    this.origAspectRatio,
    this.cacheWidth,
  });

  const SimpleExtendedImage.avatar(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.placeholder = placeholderImage,
    this.replacement,
    this.fit,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.loadingSize,
    this.origAspectRatio,
    this.cacheWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 计算目标显示尺寸
    final double targetWidth = width ?? MediaQuery.sizeOf(context).width;
    final double targetHeight = height ?? MediaQuery.sizeOf(context).height;
    final BoxFit targetFit = fit ?? BoxFit.cover;

    const Map<String, String> httpHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35',
    };

    final Widget placeholderWidget = _buildPlaceholder(
      targetWidth,
      targetHeight,
    );

    Widget imageContent;

    if (url.startsWith('http') || url.startsWith('https')) {
      // --- 网络图片 ---
      imageContent = CachedNetworkImage(
        httpHeaders: httpHeaders,
        imageUrl: url,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
        useOldImageOnUrlChange: true,
        placeholder: (c, u) => LottieLoadingIndicator(
          assetPath: 'assets/animation/StarLoader.json',
          size: loadingSize ?? 60.0,
        ),
        errorWidget: (c, u, e) => placeholderWidget,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 120),
      );
    } else if (url == placeholder || url == placeholderImage) {
      imageContent = placeholderWidget;
    } else if (url.startsWith('assets/')) {
      // Flutter 资源路径（例如 assets/images/xxx.png）
      imageContent = _buildAssetImage(
        url,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
      );
    } else {
      // 本地文件路径（例如 FilePicker 选择后的本地路径）
      final localFile = File(url.split('?').first);
      imageContent = ExtendedImage.file(
        localFile,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
            case LoadState.failed:
              return placeholderWidget;
            case LoadState.completed:
              return ExtendedRawImage(
                image: state.extendedImageInfo?.image,
                width: targetWidth,
                height: targetHeight,
                fit: targetFit,
              );
          }
        },
      );
    }

    if (shape == BoxShape.circle) {
      return ClipOval(child: imageContent);
    } else if (borderRadius != null && borderRadius != BorderRadius.zero) {
      return ClipRRect(borderRadius: borderRadius!, child: imageContent);
    } else {
      return imageContent;
    }
  }

  Widget _buildPlaceholder(double targetWidth, double targetHeight) {
    final side = _placeholderIconSize(targetWidth, targetHeight);

    return SizedBox(
      width: targetWidth,
      height: targetHeight,
      child: Center(
        child: _buildAssetImage(
          placeholder,
          width: side,
          height: side,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildAssetImage(
    String assetPath, {
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.asset(assetPath, width: width, height: height, fit: fit);
  }

  double _placeholderIconSize(double targetWidth, double targetHeight) {
    final candidates = <double>[
      if (targetWidth.isFinite && targetWidth > 0) targetWidth,
      if (targetHeight.isFinite && targetHeight > 0) targetHeight,
    ];

    final shortestSide = candidates.isEmpty
        ? 96.0
        : candidates.reduce(
            (value, element) => value < element ? value : element,
          );

    return (shortestSide * 0.48).clamp(42.0, 96.0).toDouble();
  }
}
