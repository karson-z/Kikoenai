import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';

import '../../constants/app_images.dart';

class SimpleExtendedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final BoxFit? fit;
  final int? cacheWidth;
  final double? loadingSize;

  const SimpleExtendedImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.loadingSize,
    this.cacheWidth,
  });

  const SimpleExtendedImage.avatar(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.loadingSize,
    this.cacheWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    // 规范化 URL，统一处理 null
    final String safeUrl = url ?? '';

    // 解析目标尺寸：优先构造参数，其次 MediaQuery 屏幕尺寸
    // 注意：不使用 LayoutBuilder，因为 WoltModalSheet 等无界父级会传递
    // BoxConstraints(biggest)，导致 Icon(size: infinity) 崩溃。
    final double targetWidth = width ?? MediaQuery.sizeOf(context).width;
    final double targetHeight = height ?? MediaQuery.sizeOf(context).height;
    final BoxFit targetFit = fit ?? BoxFit.cover;

    const Map<String, String> httpHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35',
    };

    Widget imageContent;

    if (safeUrl.startsWith('http') || safeUrl.startsWith('https')) {
      // --- 网络图片 ---
      imageContent = CachedNetworkImage(
        httpHeaders: httpHeaders,
        imageUrl: safeUrl,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
        memCacheWidth: cacheWidth,
        useOldImageOnUrlChange: true,
        placeholder: (c, u) => LottieLoadingIndicator(
          assetPath: 'assets/animation/StarLoader.json',
          size: loadingSize ?? 60.0,
        ),
        errorBuilder: (c, u, e) => _buildAssetImage(
          placeholderImage,
          width: targetWidth,
          height: targetHeight,
          fit: targetFit,
        ),
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 120),
      );
    } else if (safeUrl.startsWith('assets/')) {
      imageContent = _buildAssetImage(
        safeUrl,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
      );
    } else if (safeUrl.isEmpty) {
      // 空 URL：灰色背景 + 音乐图标，避免 ExtendedFileImageProvider 抛 PathNotFoundException
      imageContent = _buildPlaceholder();
    } else {
      // 本地文件路径
      final localFile = _resolveLocalFile(safeUrl);
      imageContent = ExtendedImage.file(
        localFile,
        width: targetWidth,
        height: targetHeight,
        fit: targetFit,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return _buildPlaceholder();
            case LoadState.failed:
              return _buildAssetImage(
                placeholderImage,
                width: targetWidth,
                height: targetHeight,
                fit: targetFit,
              );
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

  /// 解析本地文件路径，兼容 file:// 协议头和查询参数
  File _resolveLocalFile(String rawUrl) {
    String path = rawUrl;
    // 去掉查询参数
    final queryIndex = path.indexOf('?');
    if (queryIndex >= 0) {
      path = path.substring(0, queryIndex);
    }
    // 处理 file:// 协议头
    if (path.startsWith('file://')) {
      return File(Uri.parse(path).toFilePath());
    }
    return File(path);
  }

  /// 构建空 URL 占位图（url 为空/null 时使用）：灰色背景 + 音乐图标。
  /// 通过 LayoutBuilder 感知父组件约束；父约束无界时（如 WoltModalSheet 传递
  /// BoxConstraints(biggest)）回退到构造参数或 MediaQuery 屏幕尺寸，
  /// 避免 Icon(size: infinity) 崩溃。
  Widget _buildPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 优先用父组件约束，无界时回退到构造参数 / MediaQuery
        final double w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (width ?? MediaQuery.sizeOf(context).width);
        final double h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (height ?? MediaQuery.sizeOf(context).height);
        final double size = math.min(w, h);
        final double iconSize = size * 0.5;

        return SizedBox(
          width: w,
          height: h,
          child: ColoredBox(
            color: const Color(0xFFE5E6E8),
            child: Center(
              child: iconSize > 0
                  ? Icon(Icons.music_note_outlined, size: iconSize)
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
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
}
