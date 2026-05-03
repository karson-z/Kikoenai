import 'dart:async';
import 'dart:io';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

class ColorUtils {
  /// 从图片 URL 或本地文件获取 Palette
  /// 返回 PaletteGenerator
  static Future<PaletteGeneratorMaster> getImagePalette(String url) async {
    ImageProvider imageProvider;

    if (url.replaceAll('?param=500y500', '').isEmpty) {
      imageProvider = const ExtendedAssetImageProvider('assets/images/placeholder.png');
    } else if (url.startsWith('http')) {
      imageProvider = CachedNetworkImageProvider(
        url,
        headers: const {
          'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35'
        },
      );
    } else {
      imageProvider = ExtendedFileImageProvider(File(url.split('?').first));
    }
    return await PaletteGeneratorMaster.fromImageProvider(
      imageProvider,
      maximumColorCount: 12,
    );
  }


  /// 获取主色、鲜艳色、柔和色
  static Future<Color> getMainColors(String url) async {
    final palette = await getImagePalette(url);

    Color defaultColor = const Color(0xFF001F3F); // 墨蓝色

    Color dominant = palette.dominantColor?.color ?? defaultColor;

    return dominant;
  }

  /// 根据主色和柔和色生成渐变
  static LinearGradient buildGradient({
    required Color? start,
    Color? end,
    Alignment begin = Alignment.topLeft,
    Alignment endAlign = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [
        start ?? Colors.grey.shade900,
        end ?? (start ?? Colors.grey.shade900).withOpacity(0.7),
      ],
      begin: begin,
      end: endAlign,
    );
  }
}
