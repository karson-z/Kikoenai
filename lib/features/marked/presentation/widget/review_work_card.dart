import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. 引入 Riverpod
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/submit/handle_submit.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/data/model/work.dart';

import '../../../album/data/model/user_work_status.dart';
import '../../../album/presentation/widget/rating_section.dart';
import '../../../album/presentation/widget/review_bottom_sheet.dart'; // 引入 BottomSheet
import '../../../../core/widgets/common/kikoenai_dialog.dart'; // 引入 Dialog 工具
import '../../../../core/enums/work_progress.dart';

// 2. 改为 ConsumerWidget 以获取 ref
class WorkListCard extends ConsumerWidget {
  final Work work;

  const WorkListCard({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 3. build 方法增加 ref 参数
    // 提取声优名称，如果有多个用逗号连接
    final vaNames = work.vas?.map((va) => va.name).join(' ') ?? '';

    // 组合元数据文本：社团 / 发售日 / 声优
    final metaTextParts = [work.circle?.name, work.release, vaNames]
        .where((e) => e != null && e.isNotEmpty)
        .join(' / ');

    // 辅助方法：打开编辑弹窗
    void showEditSheet() {
      // 构建初始状态
      final initialStatus = UserWorkStatus(
        workId: work.id ?? 0,
        rating: (work.userRating is int) ? work.userRating : 0,
        // 如果列表接口没返回 reviewText 和 progress，这里只能给默认值
        // 或者如果 work 对象里有这些字段，请对应填入
        reviewText: '',
        progress: WorkProgress.marked,
      );

      KikoenaiDialog.showBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) {
          return ReviewBottomSheet(
            initialStatus: initialStatus,
            onSubmit: (newStatus) {
              // 调用通用的提交逻辑
              HandleSubmit.handleRatingSubmit(context, ref, newStatus);
            },
          );
        },
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.detail, extra: {'work': work});
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 左侧封面图
              SimpleExtendedImage(
                work.mainCoverUrl ?? '',
                width: 100, // 稍微调小一点，列表页通常不需要太大
                height: 100,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),

              const SizedBox(width: 12),

              // 2. 右侧信息列
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      work.title ?? '无标题',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // 元数据行
                    Text(
                      metaTextParts,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // 评分行
                    // 使用 SingleChildScrollView 防止 RatingSection 内容过宽导致溢出
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child:RatingSection(
                        // 1. 基础数据 (移除已废弃的 totalCount/details/duration 参数)
                        average: work.rateAverage2dp ?? 0,

                        // 2. 动态数据
                        userRating: (work.userRating is int) ? work.userRating : 0,

                        // 3. 交互回调
                        onRatingUpdate: (int newRating) {
                          final currentStatus = UserWorkStatus(workId: work.id ?? 0);
                          final newStatus = currentStatus.copyWith(
                            rating: newRating,
                            workId: work.id,
                          );
                          HandleSubmit.handleRatingSubmit(context, ref, newStatus);
                        },
                        extraWidgets: [

                          if (work.updatedAt != null) ...[
                            const SizedBox(width: 8), // 控制与分数的间距
                            Text(
                              work.updatedAt!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 底部操作栏：ID 徽章 + 编辑按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐
                      children: [
                        // ID Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            work.sourceId ?? work.originalWorkno ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // 编辑按钮 (点击打开 BottomSheet)
                        InkWell(
                          onTap: showEditSheet, // 绑定点击事件
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0), // 增加点击热区
                            child: Icon(
                              Icons.edit,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
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