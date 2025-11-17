import 'package:flutter/material.dart';
import 'package:name_app/features/album/data/model/work.dart';

class WorkListItem extends StatelessWidget {
  final Work workInfo;

  const WorkListItem({
    super.key,
    required this.workInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        elevation: 0, // 你要边框就不要阴影了
        child: Row(
          children: [
            // 图片贴满高度
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.asset(
                workInfo.title,
                width: 55,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 6),

            // 文本区域
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workInfo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    workInfo.title,
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

            // 右侧 >
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
