import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

import '../../routes/app_routes.dart';

class WorkListItem extends StatelessWidget {
  final Work workInfo;

  const WorkListItem({
    super.key,
    required this.workInfo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          context.push(AppRoutes.detail, extra: {'work': workInfo});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                  child: SimpleExtendedImage(
                    workInfo.samCoverUrl!,
                    width: 55,
                    fit: BoxFit.cover,
                    loadingSize: 55.0,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workInfo.title ?? "暂无标题",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        workInfo.name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Flexible(
                  flex: 0,
                  child: Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
