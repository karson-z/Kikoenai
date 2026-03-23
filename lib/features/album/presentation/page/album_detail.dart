import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/utils/submit/handle_submit.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
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
// 确保引入 FileNode
import '../../../../core/service/file/file_scanner_storage.dart'; // 引入你的本地存储类

/// 专辑详情页
class AlbumDetailPage extends ConsumerWidget {
  final Map<String, dynamic> extra;

  const AlbumDetailPage({super.key, required this.extra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var work = extra['work'];
    if (work is Map) {
      work = Work.fromJson(work as Map<String, dynamic>);
    }

    // 1. 提取本地标识，默认为 false
    final bool isLocal = extra['isLocal'] as bool? ?? false;

    // 2. 如果是本地模式，禁用网络 Provider 监听
    final workStatus = isLocal ? null : ref.watch(workDetailProvider(work.id));
    final asyncData = isLocal ? null : ref.watch(trackFileNodeProvider(work.id));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "RJ0${work.id}",
          style: const TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          // 3. 本地模式下禁用状态标记按钮，只展示 "本地" 标签
          if (isLocal)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "本地作品",
                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          else
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

                KikoenaiDialog.showBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (ctx) {
                    return ReviewBottomSheet(
                      initialStatus: initialStatus,
                      onSubmit: (newStatus) async {
                        await HandleSubmit.handleRatingSubmit(context, ref, newStatus);
                        ref.invalidate(workDetailProvider(work.id));
                      },
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_add_outlined, color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    workStatus!.when(
                      data: (status) {
                        return Text(
                          WorkProgress.fromString(status.progress).label,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                      error: (_, __) => const Text(
                        "标记",
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (work.name != null)
                GestureDetector(
                  onTap: () {
                    // 即使是本地模式，标签跳转功能一般也可以保留（如果分类页支持全局浏览的话）
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
                average: work.rateAverage2dp ?? 0,
                // 4. 本地模式下读取不到网络评分，默认为 0
                userRating: isLocal ? 0 : (workStatus?.value?.userRating ?? 0),
                extraWidgets: [
                  RatingMetaItem(
                      icon: Icons.comment,
                      text: "(${work.reviewCount ?? 0})"
                  ),
                  if ((work.duration ?? 0) > 0)
                    RatingMetaItem(
                        icon: Icons.timer,
                        text: "(${TimeFormatter.formatSeconds(work.duration!)})"
                    )
                ],
                // 5. 本地模式下禁用评分提交
                onRatingUpdate: isLocal
                    ? (int _) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('本地模式下无法提交评价')),
                  );
                }
                    : (int newRating) {
                  final currentStatus = UserWorkStatus(workId: work.id);
                  final newStatus = currentStatus.copyWith(
                    rating: newRating,
                    workId: work.id,
                  );
                  HandleSubmit.handleRatingSubmit(context, ref, newStatus);
                  ref.invalidate(workDetailProvider(work.id));
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

          // 核心滚动视图（包含 metadata 和 树形列表）
          Widget buildScrollBody() {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: metadata,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 6. 根据是否是本地模式渲染不同的列表源
                if (isLocal)
                // 本地模式：直接从 FileScannerStorage 拿取匹配此 RJ 码的节点
                  Builder(builder: (context) {
                    // 极其清爽的调用！全量跨路径查找并组装！
                    final localWorkTree = FileScannerStorage().getWorkFileTreeLocally(work.id);

                    if (localWorkTree == null) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text("本地未找到该作品的文件", style: TextStyle(color: Colors.grey))),
                      );
                    }

                    if (localWorkTree.children == null || localWorkTree.children!.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text("该文件夹内部为空", style: TextStyle(color: Colors.grey))),
                      );
                    }

                    return FileNodeBrowser(
                      work: work,
                      rootNodes: localWorkTree.children!,
                    );
                  })
                else
                // 网络模式：渲染异步加载的数据
                  asyncData!.when(
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: LottieLoadingIndicator(message: 'loading...')),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: err is GlobalException
                            ? Text("GlobalException: ${err.message}\ncode=${err.code}")
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
            );
          }

          // 7. 本地模式下直接返回列表，禁用下拉刷新
          return isLocal
              ? buildScrollBody()
              : RefreshIndicator(
            onRefresh: () => ref.refresh(trackFileNodeProvider(work.id).future),
            child: buildScrollBody(),
          );
        },
      ),
    );
  }
}

/// 封面组件 (保持不变)
class AlbumCover extends StatelessWidget {
  final String? thumbnailUrl;
  final String? mainUrl;
  final String? heroTag;

  const AlbumCover({super.key, this.heroTag, this.thumbnailUrl, this.mainUrl});

  @override
  Widget build(BuildContext context) {
    Widget buildThumbnail() {
      if (thumbnailUrl != null) {
        return CachedNetworkImage(
          imageUrl: thumbnailUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey.shade300),
          errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
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
            placeholder: (context, url) => buildThumbnail(),
            errorWidget: (context, url, error) => buildThumbnail(),
            fadeInDuration: const Duration(milliseconds: 400),
            useOldImageOnUrlChange: true,
          )
              : buildThumbnail(),
        ),
      ),
    );
  }
}