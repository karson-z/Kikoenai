import 'package:flutter/cupertino.dart';
import 'package:name_app/features/album/data/model/work.dart';
import 'package:name_app/core/widgets/card/work_list.dart';

import '../../../../config/work_layout_strategy.dart';

class ResponsiveListGrid extends StatelessWidget {
  final List<Work> work;

  const ResponsiveListGrid({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.list);

    final columns = layoutStrategy.getColumnsCount(context);
    final horizontalSpacing = layoutStrategy.getColumnSpacing(context);
    final verticalSpacing = layoutStrategy.getRowSpacing(context);

    return SliverGrid.builder(
      itemCount: work.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: horizontalSpacing,
        mainAxisSpacing: verticalSpacing,
        childAspectRatio: 2.6, // 横向大于纵向
      ),
      itemBuilder: (context, index) {
        return WorkListItem(workInfo: work[index]);
      },
    );
  }
}
