import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/age_rating.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/widget/work_tag.dart';
import 'package:kikoenai/features/category/provider/category_data_provider.dart';

/// 最新作品"列表模式"的卡片：展示字段与 [WorkCard] 完全一致
/// （RJ 编号 / 年龄分级 / 字幕标记 / 发售日 / 标题 / 社团名 / VA 标签 / 标签），
/// 以横向列表行布局呈现，供 [WorkListCard] 使用。
class WorkListCard extends ConsumerWidget {
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

  const WorkListCard({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面缩略图（4:3，小尺寸降低解码/内存开销）
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 88,
                  height: 66,
                  child: Hero(
                    tag: heroTag,
                    child: SimpleExtendedImage(
                      mainCoverUrl ?? '',
                      width: 88,
                      cacheWidth: 200,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 信息区
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 元信息行：RJ / 年龄分级 / 字幕标记 / 发售日
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaChip(text: 'RJ$id'),
                        if (ageCategoryString != null)
                          _MetaChip(
                            text: AgeRatingEnum.labelFromValue(
                              ageCategoryString,
                            ),
                            background: AgeRatingEnum.ageRatingColorByValue(
                              ageCategoryString,
                            ),
                          ),
                        if (isSubTitle)
                          const _MetaChip(text: '字幕', background: Colors.black45),
                        if (release != null)
                          Text(
                            release!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    if (displayName.isNotEmpty) ...[
                      const SizedBox(height: 2),
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
                              ref.invalidate(
                                categoryProvider(
                                  ref
                                      .read(
                                        searchFilterProvider(
                                          FilterModule.category,
                                        ),
                                      )
                                      .sortOption,
                                ),
                              );
                              context.go(AppRoutes.category);
                            }
                          },
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    TagRow(tags: vas ?? [], type: TagType.va),
                    // 作者标签与普通标签之间保留 1 间距
                    const SizedBox(height: 1),
                    TagRow(tags: tags ?? [], type: TagType.tag),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 元信息小徽章（RJ / 年龄分级 / 字幕标记）。
class _MetaChip extends StatelessWidget {
  final String text;
  final Color? background;

  const _MetaChip({required this.text, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}
