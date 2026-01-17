import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
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
    final double targetWidth = width ?? MediaQuery.of(context).size.width;
    final double targetHeight = height ?? MediaQuery.of(context).size.height;
    final BoxFit targetFit = fit ?? BoxFit.cover;

    const Map<String, String> httpHeaders = {
      'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35'
    };

    final Widget placeholderWidget = Image.asset(
      placeholder,
      width: targetWidth,
      height: targetHeight,
      fit: targetFit,
    );

    Widget imageContent;

    if (url.startsWith('http') || url.startsWith('https')) {
      // --- 网络图片 ---
      imageContent = CachedNetworkImage(
        httpHeaders: httpHeaders,
        imageUrl: url,
        width: targetWidth,
        height: targetHeight,
        filterQuality: FilterQuality.high,
        fit: targetFit,
        useOldImageOnUrlChange: true,
        placeholder: (c, u) => LottieLoadingIndicator(
            assetPath: 'assets/animation/StarLoader.json',
            size: loadingSize ?? 60.0),
        errorWidget: (c, u, e) => placeholderWidget,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 120),
      );
    } else {
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
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    } else {
      return imageContent;
    }
  }
}