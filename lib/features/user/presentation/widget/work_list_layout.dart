import 'package:flutter/cupertino.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/work_list.dart';

import '../../../../config/work_layout_config.dart';

class ResponsiveListGrid extends StatelessWidget {
  final List<Work> work;

  const ResponsiveListGrid({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final layout = WorkLayoutConfig.list(context);

    return SliverGrid.builder(
      itemCount: work.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.columns,
        crossAxisSpacing: layout.horizontalSpacing,
        mainAxisSpacing: layout.verticalSpacing,
        childAspectRatio: 2.6, // 横向大于纵向
      ),
      itemBuilder: (context, index) {
        return WorkListItem(workInfo: work[index]);
      },
    );
  }
}
