import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/presentation/widget/work_tag.dart';
import 'package:kikoenai/features/category/presentation/viewmodel/provider/category_data_provider.dart';

import '../../enums/age_rating.dart';
import '../../enums/tag_enum.dart';
import '../filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/enums/age_rating.dart';

class WorkCard extends ConsumerWidget {
  final int id;
  final String? title;
  final String? name;
  final String? circleName;
  final String? mainCoverUrl;
  final String heroTag;
  final bool? hasSubtitle;
  final String? ageCategoryString;
  final String? release;
  final List<dynamic>? vas;
  final List<dynamic>? tags;
  final VoidCallback? onTap;

  static const double kTitleFontSize = 13.0;
  static const double kSubtitleFontSize = 11.0;

  const WorkCard({
    super.key,
    required this.id,
    this.title,
    this.name,
    this.circleName,
    this.mainCoverUrl,
    required this.heroTag,
    this.hasSubtitle,
    this.ageCategoryString,
    this.release,
    this.vas,
    this.tags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubTitle = hasSubtitle ?? false;
    final displayName = name ?? circleName ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
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
                    tag: heroTag,
                    child: SimpleExtendedImage(mainCoverUrl ?? '', width: 240),
                  ),
                  _PositionedBadge(
                    top: 8,
                    left: 8,
                    text: 'RJ$id',
                    color: Colors.black.withAlpha(60),
                  ),
                  if (ageCategoryString != null)
                    _PositionedBadge(
                      top: 8,
                      right: 8,
                      text: AgeRatingEnum.labelFromValue(ageCategoryString),
                      color: AgeRatingEnum.ageRatingColorByValue(
                        ageCategoryString,
                      ),
                    ),
                  Positioned(
                    bottom: 2,
                    left: 8,
                    child: _AppIconBadge(isSubTitle: isSubTitle),
                  ),
                  if (release != null)
                    _PositionedBadge(
                      bottom: 0,
                      right: 0,
                      text: release.toString(),
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
                    Text(
                      title ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: kTitleFontSize,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          if (name != null) {
                            ref
                                .read(
                                  searchFilterProvider(
                                    FilterModule.category,
                                  ).notifier,
                                )
                                .toggleTag(TagType.circle.stringValue, name!);
                            ref.invalidate(categoryProvider);
                            context.go(AppRoutes.category);
                          }
                        },
                        child: Text(
                          displayName,
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
                    _TagsInfo(vas: vas, tags: tags),
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
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
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

class _TagsInfo extends StatelessWidget {
  final List<dynamic>? vas;
  final List<dynamic>? tags;

  const _TagsInfo({required this.vas, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TagRow(tags: vas ?? [], type: TagType.va),
        const SizedBox(height: 4),
        TagRow(tags: tags ?? [], type: TagType.tag),
      ],
    );
  }
}
