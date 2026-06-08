import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../provider/player_controller_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class BlurCacheManager {
  static const String key = 'kikoenai_blur_cache';
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 15),
      maxNrOfCacheObjects: 100,
    ),
  );
}

class BlurProcessParams {
  final Uint8List imageBytes;
  final int blurRadius;
  final int resizeWidth;
  final int quality;

  BlurProcessParams({
    required this.imageBytes,
    required this.blurRadius,
    required this.resizeWidth,
    required this.quality,
  });
}

class BlurredImageService {
  static final BlurredImageService _instance = BlurredImageService._internal();
  factory BlurredImageService() => _instance;
  BlurredImageService._internal();

  Box<dynamic> get settingsBox => AppStorage.settingsBox;

  Future<File?> getBlurredImage(String url) async {
    if (url.isEmpty) return null;

    // 获取当前设置参数
    final blurBg = settingsBox.get(
      StorageKeys.blurBackground,
      defaultValue: 10,
    );
    final resizeBg = settingsBox.get(
      StorageKeys.backgroundScale,
      defaultValue: 100,
    );
    final qualityBg = settingsBox.get(
      StorageKeys.backgroundQuality,
      defaultValue: 70,
    );

    // 2. 构建唯一的 Cache Key（将 URL 和参数绑定）
    final String customCacheKey = '${url}_${blurBg}_${resizeBg}_$qualityBg';

    // 3. 尝试从专属的 CacheManager 中获取缓存
    // 这里会自动触发 LRU 算法的 "Touch" 操作，更新最近访问时间
    final FileInfo? fileInfo = await BlurCacheManager.instance.getFileFromCache(
      customCacheKey,
    );
    if (fileInfo != null) {
      return fileInfo.file;
    }

    try {
      // 4. 如果没有缓存，从默认的全局 CacheManager 获取原图
      final File originalFile = await DefaultCacheManager().getSingleFile(url);
      final Uint8List imageBytes = await originalFile.readAsBytes();

      final params = BlurProcessParams(
        imageBytes: imageBytes,
        blurRadius: blurBg,
        resizeWidth: resizeBg,
        quality: qualityBg,
      );
      final Uint8List? blurredBytes = await compute(
        _processBlurInIsolate,
        params,
      );

      if (blurredBytes != null) {
        final File savedFile = await BlurCacheManager.instance.putFile(
          customCacheKey,
          blurredBytes,
          fileExtension: 'jpg',
        );
        return savedFile;
      }
    } catch (e) {
      debugPrint('Error generating blurred image: $e');
    }

    return null;
  }

  static Future<Uint8List?> _processBlurInIsolate(
    BlurProcessParams params,
  ) async {
    final totalStopwatch = Stopwatch()..start();
    final stepStopwatch = Stopwatch()..start();

    final img.Image? decodedImage = img.decodeImage(params.imageBytes);
    if (decodedImage == null) {
      debugPrint('图片解码失败');
      return null;
    }
    debugPrint('1. 解码耗时: ${stepStopwatch.elapsedMilliseconds} ms');
    stepStopwatch.reset();

    final int origWidth = decodedImage.width;
    final int safeResizeWidth = origWidth < params.resizeWidth
        ? origWidth
        : params.resizeWidth;

    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: safeResizeWidth,
    );
    debugPrint('=> 缩放后尺寸: ${resizedImage.width} x ${resizedImage.height}');
    debugPrint('2. 缩放耗时: ${stepStopwatch.elapsedMilliseconds} ms');
    stepStopwatch.reset();

    final img.Image blurredImage = img.gaussianBlur(
      resizedImage,
      radius: params.blurRadius,
    );
    debugPrint('3. 模糊耗时: ${stepStopwatch.elapsedMilliseconds} ms');
    stepStopwatch.reset();

    final Uint8List resultBytes = img.encodeJpg(
      blurredImage,
      quality: params.quality,
    );
    debugPrint('4. 编码耗时: ${stepStopwatch.elapsedMilliseconds} ms');

    totalStopwatch.stop();
    debugPrint('=> 总计耗时: ${totalStopwatch.elapsedMilliseconds} ms');
    return resultBytes;
  }
}

final blurredImageProvider = FutureProvider.autoDispose<File?>((ref) async {
  final coverUrl = ref.watch(
    playerControllerProvider.select((s) => s.currentItem?.displayCoverUrl),
  );

  if (coverUrl == null || coverUrl.isEmpty) {
    return null;
  }

  return BlurredImageService().getBlurredImage(coverUrl);
});

class PlayerBackground extends ConsumerWidget {
  const PlayerBackground({super.key, required this.expVal});
  final double expVal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blurredImageAsync = ref.watch(blurredImageProvider);
    final File? currentFile = blurredImageAsync.value;
    final baseColor = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: currentFile != null
              ? SimpleExtendedImage(
                  currentFile.path,
                  key: ValueKey(currentFile.path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              : const SizedBox.shrink(
                  // 当没有图片时，SizedBox 是透明的，会完美露出上面的 AnimatedContainer 纯色
                  key: ValueKey('empty_bg'),
                ),
        ),

        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black38, Colors.black87],
            ),
          ),
        ),
        Container(
          color: baseColor.withValues(alpha: 1 - expVal.clamp(0.0, 1.0)),
        ),
      ],
    );
  }
}
