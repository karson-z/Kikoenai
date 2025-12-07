import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/global_exception.dart';
import '../../../../core/enums/tag_enum.dart';
import '../viewmodel/provider/audio_file_provider.dart';
import '../widget/file_box.dart';
import '../widget/rating_section.dart';
import '../widget/work_tag.dart';

/// 专辑详情页
class AlbumDetailPage extends ConsumerWidget {
  final Map<String, dynamic> extra;
  const AlbumDetailPage({super.key, required this.extra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = extra['work'];
    final asyncData = ref.watch(trackFileNodeProvider(work.id));
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("RJ${work.id}" ,style: TextStyle(fontSize: 18),),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          GestureDetector(
            child: Row(
              children: const [
                Icon(
                  Icons.table_chart,
                  color: Colors.grey,                // 随便染成你要的颜色
                ),
                SizedBox(width: 4),
                Text(
                  "标记",
                  style: TextStyle(fontSize: 16,color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          // 封面
          final cover = AlbumCover(
            heroTag: work.heroTag,
            thumbnailUrl: work.thumbnailCoverUrl,
            mainUrl: work.mainCoverUrl,
          );

          // 基本信息
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(work.title ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (work.name != null)
                Text(work.name!,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              if (work.vas != null)
                TagRow(tags: work.vas!, type: TagType.author),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("${work.price ?? 0} JPY",
                      style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(width: 20),
                  Text("销量: ${work.dlCount ?? 0}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              RatingSection(
                average: work.rateAverage2dp ?? 0,
                totalCount: work.reviewCount ?? 0,
                details: work.rateCountDetail ?? [],
                duration: work.duration ?? 0,
              ),
              const SizedBox(height: 12),
              if (work.tags != null) TagRow(tags: work.tags!),
            ],
          );

          final metadata = isWide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 3, child: cover),
              const SizedBox(width: 16),
              Flexible(flex: 6, child: info),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [cover, const SizedBox(height: 16), info],
          );

          return RefreshIndicator(onRefresh: () => ref.refresh(trackFileNodeProvider(work.id).future),
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: metadata,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: const SizedBox(height: 24),
                    ),
                  ];
                },
                body: asyncData.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) {
                    if (err is GlobalException) {
                      return Center(
                        child: Text(
                          "GlobalException: ${err.message}\ncode=${err.code}",
                        ),
                      );
                    }
                    return Center(child: Text("Other error: $err"));
                  },
                  data: (nodes) => FileNodeBrowser(
                    work: work,
                    rootNodes: nodes,
                    // 注意 FileNodeBrowser 内部 ListView 要用 `physics: ClampingScrollPhysics()` 或默认
                  ),
                ),
              ));
        },
      ),
    );
  }
}

/// 封面组件：Hero + 缩略图动画 + 大图加载
/// 修复后的封面组件
class AlbumCover extends StatelessWidget {
  final String? thumbnailUrl;
  final String? mainUrl;
  final String? heroTag;

  const AlbumCover({super.key, this.heroTag, this.thumbnailUrl, this.mainUrl});

  @override
  Widget build(BuildContext context) {
    // 构建缩略图组件 (作为占位符)
    Widget buildThumbnail() {
      if (thumbnailUrl != null) {
        return CachedNetworkImage(
          imageUrl: thumbnailUrl!,
          fit: BoxFit.cover,
          // 缩略图本身不需要占位符，或者用灰色背景
          placeholder: (context, url) => Container(color: Colors.grey.shade300),
          errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
        );
      }
      return Container(color: Colors.grey.shade300);
    }

    return Hero(
      tag: heroTag ?? '',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: mainUrl != null
              ? CachedNetworkImage(
            imageUrl: mainUrl!,
            fit: BoxFit.cover,
            // ✅ 关键修复：直接使用 placeholder 属性展示缩略图
            // 当大图加载时，CachedNetworkImage 会自动处理从 placeholder 到大图的过渡
            placeholder: (context, url) => buildThumbnail(),
            // 如果大图加载失败，保留缩略图或显示错误
            errorWidget: (context, url, error) => buildThumbnail(),
            // 淡入动画时长
            fadeInDuration: const Duration(milliseconds: 400),
            // 确保淡入时占位符不会立即消失，而是平滑过渡
            useOldImageOnUrlChange: true,
          )
              : buildThumbnail(),
        ),
      ),
    );
  }
}
