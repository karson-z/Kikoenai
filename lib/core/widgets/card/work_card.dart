import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/widget/work_tag.dart';
import '../../../features/category/presentation/viewmodel/provider/category_data_provider.dart';
import '../../enums/age_rating.dart';
import '../../enums/tag_enum.dart';

class WorkCard extends StatelessWidget {
  final Work work;

  // 新增可选字段
  final String? lastTrackTitle; // 上次播放到哪一集
  final DateTime? lastPlayedAt; // 上次播放时间

  WorkCard({
    super.key,
    required this.work,
    this.lastTrackTitle,
    this.lastPlayedAt,
  });

  @override
  Widget build(BuildContext context) {
    final showHistoryInfo = lastTrackTitle != null && lastPlayedAt != null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        context.push(AppRoutes.detail, extra: {'work': work});
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final computedTitleFontSize = cardWidth / 15;
            final computedCircleFontSize = cardWidth / 20;
            double computeFontSize() => cardWidth / 20;
            double computePadding() => cardWidth / 30;
            final infoFontSize = cardWidth / 22;
            final isSubTitle = work.hasSubtitle;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面 + Hero
                Flexible(
                  child: Hero(
                    tag: work.heroTag!,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: work.thumbnailCoverUrl ?? "",
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                            const Center(child: LottieLoadingIndicator(assetPath:'assets/animation/StarLoader.json',size: 80)),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _buildBadge(
                              "RJ${work.id}",
                              Colors.black.withAlpha(60),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildBadge(
                              AgeRatingEnum.labelFromValue(work.ageCategoryString),
                              AgeRatingEnum.ageRatingColorByValue(work.ageCategoryString),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            left: 8,
                            child: AppBadge(
                              color: Colors.black45,
                              child: Icon(
                                isSubTitle ?? false ? Icons.closed_caption :Icons.closed_caption_disabled ,
                                size: 12,
                                color: Colors.white,
                              ),
                            )
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _buildBadge(
                              work.release.toString(),
                              Colors.black.withAlpha(90),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        work.title ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: computedTitleFontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Consumer(
                          builder: (context,ref,child){
                            return GestureDetector(
                              onTap: (){
                                ref.read(categoryUiProvider.notifier).toggleTag(TagType.circle.stringValue,work.name!,refreshData: true);
                                context.go(AppRoutes.category);
                              },
                              child: Text(
                                work.name ?? "",
                                style: TextStyle(
                                  fontSize: computedCircleFontSize,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        )
                      ),
                      const SizedBox(height: 6),

                      /// 根据是否有播放记录选择显示标签还是播放信息
                      if (showHistoryInfo)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "当前集: $lastTrackTitle",
                              style: TextStyle(
                                fontSize: infoFontSize,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "上次播放: ${lastPlayedAt.toString()}",
                              style: TextStyle(
                                fontSize: infoFontSize,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 作者标签
                            TagRow(
                              tags: work.vas ?? [],
                              type: TagType.va,
                              fontSize: computeFontSize(),
                              borderRadius: 8,
                              padding: EdgeInsets.all(computePadding()),
                            ),
                            const SizedBox(height: 4),

                            /// 普通标签
                            TagRow(
                              tags: work.tags ?? [],
                              type: TagType.tag,
                              fontSize: computeFontSize(),
                              borderRadius: 25,
                              padding: EdgeInsets.all(computePadding()),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
class AppBadge extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double radius;

  const AppBadge({
    Key? key,
    required this.child,
    this.color = Colors.red,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    this.radius = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: padding,
      child: Center(child: child),
    );
  }
}