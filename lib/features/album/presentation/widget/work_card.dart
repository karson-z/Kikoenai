import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:name_app/features/album/data/model/work.dart';
import 'package:name_app/features/album/presentation/widget/work_tag.dart';
import '../../../../core/enums/age_rating.dart';

class WorkCard extends StatelessWidget {
  final Work work;
  final void Function(dynamic tag)? onTagTap; // 新增：标签点击回调

  const WorkCard({
    super.key,
    required this.work,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // 卡片点击逻辑：跳详情
        Navigator.pushNamed(context, "/work/${work.id}");
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: work.thumbnailCoverUrl ?? "",
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
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
                        bottom: 0,
                        right: 0,
                        child: _buildBadge(
                          work.createDate.toString(),
                          Colors.black.withAlpha(90),
                        ),
                      ),
                    ],
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
                      Text(
                        work.name ?? "",
                        style: TextStyle(
                          fontSize: computedCircleFontSize,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      /// -----------------------
                      /// 作者标签 (可点击)
                      /// -----------------------
                      TagRow(
                        tags: work.vas ?? [],
                        type: TagType.author,
                        fontSize: computeFontSize(),
                        borderRadius: 8,
                        padding: EdgeInsets.all(computePadding()),
                        onTagTap: (tag) {
                          onTagTap?.call(tag);
                        },
                      ),

                      const SizedBox(height: 4),

                      /// -----------------------
                      /// 普通标签 (可点击)
                      /// -----------------------
                      TagRow(
                        tags: work.tags ?? [],
                        type: TagType.normal,
                        fontSize: computeFontSize(),
                        borderRadius: 25,
                        padding: EdgeInsets.all(computePadding()),
                        onTagTap: (tag) {
                          onTagTap?.call(tag);
                        },
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
