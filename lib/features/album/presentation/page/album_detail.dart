import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/utils/submit/handle_submit.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/presentation/widget/review_bottom_sheet.dart';
import '../../../../core/common/global_exception.dart';
import '../../../../core/enums/tag_enum.dart';
import '../../../../core/enums/work_progress.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/data/time_formatter.dart';
import '../../../category/presentation/viewmodel/provider/category_data_provider.dart';
import '../../data/model/user_work_status.dart';
import '../viewmodel/provider/audio_file_provider.dart';
import '../widget/file_box.dart';
import '../widget/rating_menu.dart';
import '../widget/rating_section.dart';
import '../widget/work_tag.dart';

/// 专辑详情页
class AlbumDetailPage extends ConsumerWidget {
  final Map<String, dynamic> extra;

  const AlbumDetailPage({super.key, required this.extra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = extra['work'];
    final workStatus = ref.watch(workDetailProvider(work.id));
    final asyncData = ref.watch(trackFileNodeProvider(work.id));
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "RJ${work.id}",
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              final currentData = workStatus.value;

              final initialStatus = UserWorkStatus(
                workId: work.id,
                rating: currentData?.userRating ?? 0,
                reviewText: currentData?.reviewText ?? '',
                progress: currentData?.progress != null
                    ? WorkProgress.fromString(currentData!.progress)
                    : WorkProgress.marked,
              );

              // 3. 弹出 BottomSheet
              KikoenaiDialog.showBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (ctx) {
                  return ReviewBottomSheet(
                    initialStatus: initialStatus,
                    onSubmit: (newStatus) async {
                      await HandleSubmit.handleRatingSubmit(context, ref, newStatus);
                      ref.refresh(workDetailProvider(work.id));
                    },
                  );
                },
              );
            },
            child: Padding( // 加点 padding 增加点击区域和美观度
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_add_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 4),
                  // 4. 渲染文字：处理 AsyncValue 的三种状态
                  workStatus.when(
                    data: (status) {
                      return Text(
                        WorkProgress.fromString(status.progress).label,
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                    error: (_, __) => const Text(
                      "标记", // 出错时回退到默认
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          // 封面组件
          final cover = AlbumCover(
            heroTag: work.heroTag,
            thumbnailUrl: work.thumbnailCoverUrl,
            mainUrl: work.mainCoverUrl,
          );

          // 基本信息组件
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(work.title ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (work.name != null)
                GestureDetector(
                  onTap: () {
                    ref.read(categoryUiProvider.notifier).toggleTag(
                        TagType.circle.stringValue, work.name!,
                        refreshData: true);
                    context.go(AppRoutes.category);
                  },
                  child: Text(work.name!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              const SizedBox(height: 4),
              if (work.vas != null) TagRow(tags: work.vas!, type: TagType.va),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("${work.price ?? 0} JPY",
                      style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(width: 20),
                  Text("销量: ${work.dlCount ?? 0}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              RatingSection(
                // 1. 基础数据 (来自 extra work)
                average: work.rateAverage2dp ?? 0,

                // 2. 动态数据 (来自 Riverpod workStatus)
                // 使用 value 获取当前值，如果加载中或为空，则默认为 0
                userRating: workStatus.value?.userRating ?? 0,
                extraWidgets: [
                  // 1. 评论数
                  RatingMetaItem(
                      icon: Icons.comment,
                      text: "(${work.reviewCount ?? 0})"
                  ),

                  // 2. 时长 (你可以决定是否显示，或者格式化方式)
                  if ((work.duration ?? 0) > 0)
                    RatingMetaItem(
                        icon: Icons.timer,
                        text: "(${TimeFormatter.formatSeconds(work.duration!)})"
                    )
                ],
                // 3. 交互回调 (点击星星)
                onRatingUpdate: (int newRating) {
                  // A. 获取当前状态对象 (如果是空的则新建一个)
                  final currentStatus = UserWorkStatus(workId: work.id);

                  // B. 复制并更新 rating 字段
                  final newStatus = currentStatus.copyWith(
                    rating: newRating,
                    // 确保 workId 存在
                    workId: work.id,
                  );
                  // C. 调用提交逻辑
                  HandleSubmit.handleRatingSubmit(context, ref, newStatus);
                },
              ),
              const SizedBox(height: 12),
              if (work.tags != null) TagRow(tags: work.tags!),
            ],
          );

          // 组合头部区域
          final metadata = isWide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 3, child: cover),
              const SizedBox(width: 16),
              Flexible(flex: 6, child: info),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [cover, const SizedBox(height: 16), info],
          );

          return RefreshIndicator(
            onRefresh: () => ref.refresh(trackFileNodeProvider(work.id).future),
            child: CustomScrollView(
              // 关键：确保即使内容不足也能下拉刷新
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. 头部区域 (元数据)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: metadata,
                  ),
                ),

                // 间距
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 2. 异步内容区域
                asyncData.when(
                  loading: () =>
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                        child: LottieLoadingIndicator(message: 'loading...')),
                  ),
                  error: (err, stack) =>
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: err is GlobalException
                              ? Text("GlobalException: ${err
                              .message}\ncode=${err.code}")
                              : Text("Error: $err"),
                        ),
                      ),
                  data: (nodes) {
                    return FileNodeBrowser(
                      work: work,
                      rootNodes: nodes,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 封面组件：Hero + 缩略图动画 + 大图加载
/// 修复后的封面组件
class AlbumCover extends StatelessWidget {
  final String? thumbnailUrl;
  final String? mainUrl;
  final String? heroTag;

  const AlbumCover({super.key, this.heroTag, this.thumbnailUrl, this.mainUrl});

  @override
  Widget build(BuildContext context) {
    // 构建缩略图组件 (作为占位符)
    Widget buildThumbnail() {
      if (thumbnailUrl != null) {
        return CachedNetworkImage(
          imageUrl: thumbnailUrl!,
          fit: BoxFit.cover,
          // 缩略图本身不需要占位符，或者用灰色背景
          placeholder: (context, url) => Container(color: Colors.grey.shade300),
          errorWidget: (context, url, error) =>
              Container(color: Colors.grey.shade300),
        );
      }
      return Container(color: Colors.grey.shade300);
    }

    return Hero(
      tag: heroTag ?? '',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: mainUrl != null
              ? CachedNetworkImage(
            imageUrl: mainUrl!,
            fit: BoxFit.cover,
            // ✅ 关键修复：直接使用 placeholder 属性展示缩略图
            // 当大图加载时，CachedNetworkImage 会自动处理从 placeholder 到大图的过渡
            placeholder: (context, url) => buildThumbnail(),
            // 如果大图加载失败，保留缩略图或显示错误
            errorWidget: (context, url, error) => buildThumbnail(),
            // 淡入动画时长
            fadeInDuration: const Duration(milliseconds: 400),
            // 确保淡入时占位符不会立即消失，而是平滑过渡
            useOldImageOnUrlChange: true,
          )
              : buildThumbnail(),
        ),
      ),
    );
  }
}
