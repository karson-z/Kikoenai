import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/widget/work_tag.dart';
import '../../../features/category/presentation/viewmodel/provider/category_data_provider.dart';
import '../../enums/age_rating.dart';
import '../../enums/tag_enum.dart';

class WorkCard extends ConsumerWidget {
  final Work work;
  final String? lastTrackTitle;
  final DateTime? lastPlayedAt;
  static const double kTitleFontSize = 13.0;
  static const double kSubtitleFontSize = 11.0;
  static const double kInfoFontSize = 10.0;

  const WorkCard({
    super.key,
    required this.work,
    this.lastTrackTitle,
    this.lastPlayedAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHistoryInfo = lastTrackTitle != null && lastPlayedAt != null;
    final isSubTitle = work.hasSubtitle ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        context.push(AppRoutes.detail, extra: {'work': work});
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: work.heroTag!,
                    child: SimpleExtendedImage(
                      work.mainCoverUrl ?? '',
                      width: 240,
                    ),
                  ),
                  _PositionedBadge(
                    top: 8, left: 8,
                    text: "RJ${work.id}",
                    color: Colors.black.withAlpha(60),
                  ),
                  _PositionedBadge(
                    top: 8, right: 8,
                    text: AgeRatingEnum.labelFromValue(work.ageCategoryString),
                    color: AgeRatingEnum.ageRatingColorByValue(work.ageCategoryString),
                  ),
                  Positioned(
                    bottom: 2, left: 8,
                    child: _AppIconBadge(isSubTitle: isSubTitle),
                  ),
                  _PositionedBadge(
                    bottom: 0, right: 0,
                    text: work.release.toString(),
                    color: Colors.black.withAlpha(90),
                  ),
                ],
              ),
            ),

            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      work.title ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: kTitleFontSize,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // 社团名称 (使用 MouseRegion 包裹 GestureDetector)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        // 直接使用 build 方法传入的 ref
                        onTap: () {
                          if (work.name != null) {
                            ref.read(categoryUiProvider.notifier).toggleTag(
                                TagType.circle.stringValue,
                                work.name!,
                                refreshData: true
                            );
                            context.go(AppRoutes.category);
                          }
                        },
                        child: Text(
                          work.name ?? "",
                          style: TextStyle(
                            fontSize: kSubtitleFontSize,
                            color: Colors.grey[700],
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (showHistoryInfo)
                      _HistoryInfo(
                        trackTitle: lastTrackTitle,
                        playedAt: lastPlayedAt,
                        fontSize: kInfoFontSize,
                      )
                    else
                      _TagsInfo(work: work),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PositionedBadge extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final String text;
  final Color color;

  const _PositionedBadge({
    this.top, this.bottom, this.left, this.right,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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

class _AppIconBadge extends StatelessWidget {
  final bool isSubTitle;

  const _AppIconBadge({required this.isSubTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Center(
        child: Icon(
          isSubTitle ? Icons.closed_caption : Icons.closed_caption_disabled,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HistoryInfo extends StatelessWidget {
  final String? trackTitle;
  final DateTime? playedAt;
  final double fontSize;

  const _HistoryInfo({
    required this.trackTitle,
    required this.playedAt,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "当前: $trackTitle",
          style: TextStyle(fontSize: fontSize, color: Colors.blueAccent),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          "上次: ${playedAt.toString().split('.')[0]}",
          style: TextStyle(fontSize: fontSize, color: Colors.green),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TagsInfo extends StatelessWidget {
  final Work work;

  const _TagsInfo({required this.work});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TagRow(tags: work.vas ?? [], type: TagType.va),
        const SizedBox(height: 4),
        TagRow(tags: work.tags ?? [], type: TagType.tag),
      ],
    );
  }
}