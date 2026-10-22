import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai_core/core/model/album/work.dart';
import 'package:kikoenai/core/widgets/card/work_list.dart';

import 'package:kikoenai/core/theme/app_layout_tokens.dart';

class ResponsiveListGrid extends StatelessWidget {
  final List<Work> work;

  const ResponsiveListGrid({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return SliverGrid.builder(
      itemCount: work.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: switch (layout.size) {
          AppLayoutSize.compact => 1,
          AppLayoutSize.medium => 2,
          AppLayoutSize.expanded => 3,
        },
        crossAxisSpacing: layout.gridGap,
        mainAxisSpacing: layout.gridGap,
        childAspectRatio: 2.6, // 横向大于纵向
      ),
      itemBuilder: (context, index) {
        final item = work[index];
        return WorkListItem(
          imageUrl: item.mainCoverUrl,
          title: item.title,
          name: item.name,
          onTap: () {
            context.push(AppRoutes.detail, extra: {'work': item});
          },
        );
      },
    );
  }
}
