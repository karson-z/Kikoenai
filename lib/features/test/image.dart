import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheTestPage extends StatefulWidget {
  const ImageCacheTestPage({super.key});

  @override
  State<ImageCacheTestPage> createState() => _ImageCacheTestPageState();
}

class _ImageCacheTestPageState extends State<ImageCacheTestPage> {
  // 使用 Key 来强制刷新 UI，模拟重新进入页面的效果
  Key _listKey = UniqueKey();

  // 测试用图源 (使用 Picsum 获取随机图片)
  final String _normalImage = 'https://img.dlsite.jp/modpub/images2/work/doujin/RJ01429000/RJ01428677_img_main.jpg'; // 正常图片
  final String _largeImage = 'https://img.dlsite.jp/modpub/images2/work/doujin/RJ01429000/RJ01428682_img_main.jpg';   // 较大图片
  final String _errorImage = 'https://invalid-url.com/image.png';     // 错误链接

  /// 清除缓存并刷新页面
  Future<void> _clearCacheAndReload() async {
    // 显示 Loading 提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在清理缓存...'), duration: Duration(milliseconds: 500)),
    );

    // 1. 清除磁盘和内存缓存
    await DefaultCacheManager().emptyCache();

    // 2. 也是为了确保图片组件完全重置，更新 Key
    setState(() {
      _listKey = UniqueKey();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清除，图片将重新从网络下载')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片缓存测试台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除缓存并重置',
            onPressed: _clearCacheAndReload,
          )
        ],
      ),
      // 使用 Key 强制重建 ListView，配合清除缓存测试冷启动效果
      body: ListView(
        key: _listKey,
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('1. 标准加载 (带进度条)'),
          _buildCard(
            CachedNetworkImage(
              imageUrl: _normalImage,
              // 占位符：加载时显示
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              // 错误组件：加载失败显示
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
            ),
            '首次加载可见转圈，再次加载直接显示',
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('2. 错误处理测试'),
          _buildCard(
            CachedNetworkImage(
              imageUrl: _errorImage,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  Text('加载失败', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            '当 URL 无效时显示的自定义组件',
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('3. 高级用法 (进度百分比 + 模糊哈希)'),
          _buildCard(
            CachedNetworkImage(
              imageUrl: _largeImage,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.3))
                    ]
                ),
              ),
              // 使用 progressIndicatorBuilder 可以获取下载进度
              progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: downloadProgress.progress),
                    const SizedBox(height: 8),
                    Text('${((downloadProgress.progress ?? 0) * 100).toInt()}%'),
                  ],
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            '自定义圆角、阴影以及下载进度百分比',
            height: 250,
          ),
        ],
      ),
    );
  }

  // 辅助构建 UI 的方法
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildCard(Widget content, String description, {double height = 200}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200], // 背景色，方便看清占位区域
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: content,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
          child: Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ),
      ],
    );
  }
}