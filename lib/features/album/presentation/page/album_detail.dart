import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/utils/submit/handle_submit.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/drawer/kikoenai_inner_drawer.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/provider/work_provider.dart';
import 'package:kikoenai/features/album/presentation/widget/review_bottom_sheet.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import '../../../../core/common/global_exception.dart';
import '../../../../core/enums/tag_enum.dart';
import '../../../../core/enums/work_progress.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/data/time_formatter.dart';
import '../../../../core/widgets/card/work_single_col_card.dart';
import '../../data/model/user_work_status.dart';
import '../viewmodel/provider/audio_file_provider.dart';
import '../widget/file_box.dart';
import '../widget/rating_menu.dart';
import '../widget/rating_section.dart';
import '../widget/work_tag.dart';
import '../../../../core/service/file/file_scanner_storage.dart';

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late final KikoenaiInnerDrawerController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = KikoenaiInnerDrawerController();
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    var workRaw = widget.extra['work'];
    Work? work;
    if (workRaw is Map) {
      work = Work.fromJson(workRaw as Map<String, dynamic>);
    } else if (workRaw is Work) {
      work = workRaw;
    }

    final int workId = widget.extra['workId'] as int? ?? work?.id ?? 0;
    final bool isLocal = widget.extra['isLocal'] as bool? ?? false;

    return KikoenaiInnerDrawerScope(
      controller: _drawerController,
      child: KikoenaiInnerDrawer(
        backgroundColor: isDark ? Colors.black : Colors.white,
        controller: _drawerController,
        edgeDragWidth: 300,
        drawer: AlbumDetailSimilarWorkDrawer(work: work),
        child: AlbumDetailContent(
          workId: workId,
          initialWork: work,
          isLocal: isLocal,
        ),
      ),
    );
  }
}

class AlbumDetailSimilarWorkDrawer extends ConsumerWidget {
  const AlbumDetailSimilarWorkDrawer({super.key, required this.work});
  final Work? work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (work == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final workListAsync = ref.watch(similarWorkProvider(work!.circle?.name));

    return workListAsync.when(
      data: (workList) {
        if (workList == null || workList.isEmpty) {
          return const Center(child: Text('暂无相关作品'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workList.length,
          itemBuilder: (context, index) {
            final item = workList[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: WorkSingleColCard(work: item),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('加载失败: $error')),
    );
  }
}

class SimilarWorkModel {
  final int id;
  final String title;
  final String author;
  final String cover;
  final int likes;

  SimilarWorkModel({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.likes,
  });
}

class AlbumDetailContent extends ConsumerWidget {
  final int workId;
  final Work? initialWork;
  final bool isLocal;

  const AlbumDetailContent({
    super.key,
    required this.workId,
    this.initialWork,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workStatus = isLocal ? null : ref.watch(workDetailProvider(workId));
    final Work? work = initialWork ?? workStatus?.value;

    if (work == null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("RJ0$workId", style: const TextStyle(fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          if (isLocal)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "本地作品",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                final currentData = workStatus?.value;

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
                        await HandleSubmit.handleRatingSubmit(
                            context, ref, newStatus);
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
                    const Icon(Icons.bookmark_add_outlined,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    workStatus!.when(
                      data: (status) {
                        return Text(
                          WorkProgress.fromString(status?.progress).label,
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
          IconButton(
            icon: const Icon(Icons.menu_open),
            onPressed: () {
              KikoenaiInnerDrawerScope.of(context).open();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          final cover = AlbumCover(
            heroTag: work.heroTag,
            thumbnailUrl: work.thumbnailCoverUrl,
            mainUrl: work.mainCoverUrl,
          );

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
                    ref
                        .read(searchFilterProvider(FilterModule.category).notifier)
                        .toggleTag(TagType.circle.stringValue, work.name!);
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
                userRating: isLocal ? 0 : (workStatus?.value?.userRating ?? 0),
                extraWidgets: [
                  RatingMetaItem(
                      icon: Icons.comment, text: "(${work.reviewCount ?? 0})"),
                  if ((work.duration ?? 0) > 0)
                    RatingMetaItem(
                        icon: Icons.timer,
                        text: "(${TimeFormatter.formatSeconds(work.duration!)})")
                ],
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

          Widget buildScrollBody() {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: metadata,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                if (isLocal)
                  Builder(builder: (context) {
                    final localWorkTree =
                    FileScannerStorage().getWorkFileTreeLocally(work.id);

                    if (localWorkTree == null) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text("本地未找到该作品的文件",
                                style: TextStyle(color: Colors.grey))),
                      );
                    }

                    if (localWorkTree.children == null ||
                        localWorkTree.children!.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text("该文件夹内部为空",
                                style: TextStyle(color: Colors.grey))),
                      );
                    }

                    return FileNodeBrowser(
                      work: work,
                      rootNodes: localWorkTree.children!,
                      isLocal: isLocal,
                    );
                  })
                else
                  asyncData!.when(
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: LottieLoadingIndicator(message: 'loading...')),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: err is GlobalException
                            ? Text(
                            "GlobalException: ${err.message}\ncode=${err.code}")
                            : Text("Error: $err"),
                      ),
                    ),
                    data: (nodes) {
                      return FileNodeBrowser(
                        work: work,
                        rootNodes: nodes,
                        isLocal: isLocal,
                      );
                    },
                  ),
              ],
            );
          }

          return isLocal
              ? buildScrollBody()
              : RefreshIndicator(
            onRefresh: () =>
                ref.refresh(trackFileNodeProvider(work.id).future),
            child: buildScrollBody(),
          );
        },
      ),
    );
  }
}

class AlbumCover extends StatelessWidget {
  final String? thumbnailUrl;
  final String? mainUrl;
  final String? heroTag;

  const AlbumCover({super.key, this.heroTag, this.thumbnailUrl, this.mainUrl});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag ?? '',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: SimpleExtendedImage(
            mainUrl ?? thumbnailUrl ?? '',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}