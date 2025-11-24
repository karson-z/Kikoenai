import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

import '../../constants/app_images.dart';

class SimpleExtendedImage extends StatelessWidget { // 优化1: 简化为 StatelessWidget
  final String url;
  final double? width;
  final double? height;
  final String placeholder;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget? replacement; // 实际上未被使用，可以考虑删除
  final BoxFit? fit;
  final int? cacheWidth; // 实际上只在 avatar 构造器中用于提示，未被实现利用

  const SimpleExtendedImage(this.url,
      {super.key,
        this.width,
        this.height,
        this.placeholder = placeholderImage,
        this.replacement,
        this.fit,
        this.shape = BoxShape.rectangle,
        this.borderRadius,
        this.cacheWidth});

  const SimpleExtendedImage.avatar(this.url,
      {super.key,
        this.width,
        this.height,
        this.placeholder = placeholderImage,
        this.replacement,
        this.fit,
        this.shape = BoxShape.circle,
        this.borderRadius,
        this.cacheWidth = 300});

  @override
  Widget build(BuildContext context) {
    // 优化2: 使用传入的 width/height，而非 MediaQuery 全局尺寸
    final double targetWidth = width ?? MediaQuery.of(context).size.width;
    final double targetHeight = height ?? MediaQuery.of(context).size.height;
    final BoxFit targetFit = fit ?? BoxFit.cover;

    // 统一的 HTTP Headers (避免某些服务器防盗链)
    const Map<String, String> httpHeaders = {
      'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35'
    };

    // 统一的占位符 Widget
    final Widget placeholderWidget = Image.asset(
      placeholder,
      width: targetWidth,
      height: targetHeight,
      fit: targetFit,
    );

    if (url.startsWith('http') || url.startsWith('https')) {
      // 网络图片逻辑 (使用 CachedNetworkImage)
      final imageWidget = CachedNetworkImage(
        httpHeaders: httpHeaders,
        imageUrl: url,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
        useOldImageOnUrlChange: true,
        placeholder: (c, u) => placeholderWidget,
        errorWidget: (c, u, e) => placeholderWidget,
      );

      if (shape == BoxShape.circle) {
        // 优化3: 移除 Visibility，直接根据 shape 返回 ClipOval 或 ClipRRect
        return ClipOval(child: imageWidget);
      } else {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(0),
          child: imageWidget,
        );
      }
    } else {
      // 本地图片逻辑 (使用 ExtendedImage.file)
      final localFile = File(url.split('?').first);

      Widget extendedImage = ExtendedImage.file(
        localFile,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
            case LoadState.failed: // 失败和加载中都显示占位图
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

      if (shape == BoxShape.circle) {
        return ClipOval(child: extendedImage);
      } else {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(0),
          child: extendedImage,
        );
      }
    }
  }
}