import 'package:flutter/cupertino.dart';
import 'package:name_app/features/album/data/model/work.dart';

import '../../../user/data/models/limit_work_info.dart';
import '../../../user/presentation/widget/work_list.dart';

class VerticalCardColumn extends StatelessWidget {
  final List<Work> items;
  final double width;
  final double cardHeight;
  final double maxHeight; // 新增，用于限制列高度

  const VerticalCardColumn({
    super.key,
    required this.items,
    required this.width,
    this.cardHeight = 75,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    // 内部最多显示三个卡片
    final displayedItems = items.length > 3 ? items.sublist(0, 3) : items;

    return SizedBox(
      width: width,
      height: maxHeight, // 固定高度
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: displayedItems
            .map((item) => SizedBox(
          width: width,
          height: cardHeight,
          child: WorkListItem(workInfo: item),
        ))
            .toList(),
      ),
    );
  }
}
