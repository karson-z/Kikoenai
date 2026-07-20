import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/presentation/widget/work_tag.dart';

import '../../enums/tag_enum.dart';

class WorkSingleColCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final List<dynamic>? vas;
  final List<dynamic>? tags;
  final VoidCallback? onTap;

  const WorkSingleColCard({
    super.key,
    this.imageUrl,
    this.title,
    this.vas,
    this.tags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SimpleExtendedImage(imageUrl ?? '', height: 72, width: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  TagRow(tags: vas ?? [], type: TagType.va),
                  const SizedBox(height: 4),
                  TagRow(tags: tags ?? [], type: TagType.tag),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
