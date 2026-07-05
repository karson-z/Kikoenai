import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/enums/work_progress.dart';
import 'package:kikoenai/core/routes/app_routes.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/core/utils/submit/handle_submit.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/core/widgets/drawer/kikoenai_inner_drawer.dart';
import 'package:kikoenai/core/widgets/filter/provider/filter_search_notifier.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/features/album/data/model/tag.dart';
import 'package:kikoenai/features/album/data/model/va.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/provider/audio_file_provider.dart';
import 'package:kikoenai/features/album/presentation/viewmodel/provider/work_provider.dart';
import 'package:kikoenai/features/album/presentation/widget/album_file_section.dart';
import 'package:kikoenai/features/album/presentation/widget/rating_menu.dart';
import 'package:kikoenai/features/album/presentation/widget/rating_section.dart';
import 'package:kikoenai/features/album/presentation/widget/review_bottom_sheet.dart';
import 'package:kikoenai/features/album/presentation/widget/work_tag.dart';
import 'package:kikoenai/core/widgets/card/work_single_col_card.dart';

import '../../data/model/user_work_status.dart';


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

    // 解析路由参数，取出 Work / workId / isLocal
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
        drawer: AlbumDetailSimilarWorkDrawer(
          circleName: work?.circle?.name,
          workId: workId,
          hasInitialWork: work != null,
          isLocal: isLocal,
        ),
        child: AlbumDetailContainer(
          workId: workId,
          initialWork: work,
          isLocal: isLocal,
        ),
      ),
    );
  }
}

class AlbumDetailSimilarWorkDrawer extends ConsumerWidget {
  const AlbumDetailSimilarWorkDrawer({
    super.key,
    required this.circleName,
    required this.workId,
    this.hasInitialWork = false,
    this.isLocal = false,
  });

  final String? circleName;
  final int workId;

  /// 进入时是否已携带完整 Work（列表跳转场景）。为 true 则无需等待详情接口。
  final bool hasInitialWork;

  /// 本地作品：无需拉详情接口，直接视为就绪。
  final bool isLocal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (circleName == null || circleName!.isEmpty) {
      return const Center(child: Text('暂无相关作品'));
    }

    // 就绪判定：本地 / 已有 initialWork 直接就绪；
    // 否则监听 workDetailProvider，等详情接口成功返回后才发起 /search。
    final bool ready = isLocal || hasInitialWork || _isDetailLoaded(ref);

    if (!ready) {
      return const Center(child: CircularProgressIndicator());
    }

    final workListAsync = ref.watch(similarWorkProvider(circleName));

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
              child: WorkSingleColCard(
                imageUrl: item.mainCoverUrl,
                title: item.title,
                vas: item.vas,
                tags: item.tags,
                onTap: () {
                  context.push(AppRoutes.detail, extra: {'work': item});
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('加载失败: $error')),
    );
  }

  /// 监听详情接口状态：仅当 hasValue（成功加载过）时返回 true。
  /// 注意：仅监听是否有值，不监听是否正在刷新，避免下拉刷新时抽屉闪烁。
  bool _isDetailLoaded(WidgetRef ref) {
    if (isLocal || hasInitialWork) return true;
    final asyncValue = ref.watch(workDetailProvider(workId));
    return asyncValue.hasValue;
  }
}
class AlbumDetailContainer extends ConsumerWidget {
  const AlbumDetailContainer({
    super.key,
    required this.workId,
    this.initialWork,
    required this.isLocal,
  });

  final int workId;
  final Work? initialWork;
  final bool isLocal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workStatus = isLocal ? null : ref.watch(workDetailProvider(workId));
    final Work? work = initialWork ?? workStatus?.value;

    if (work == null) {
      return _AlbumDetailLoadingScaffold(workId: workId);
    }

    // 解析评价按钮文本：null 表示加载中（显示 spinner），仅 !isLocal 时有意义
    final String? reviewLabel = isLocal
        ? null
        : workStatus!.when(
            data: (s) => WorkProgress.fromString(s?.progress).label,
            error: (_, __) => '标记',
            loading: () => null,
          );

    // 选择文件区段子类，不在视图层用 if 切换
    final Widget fileSection = switch (isLocal) {
      true => LocalAlbumFileSection(work: work),
      false => RemoteAlbumFileSection(work: work),
    };

    return AlbumDetailView(
      heroTag: work.effectiveHeroTag,
      thumbnailCoverUrl: work.thumbnailCoverUrl,
      mainCoverUrl: work.mainCoverUrl,
      workId: work.id,
      title: work.title,
      circleName: work.name,
      price: work.price,
      dlCount: work.dlCount,
      rateAverage2dp: work.rateAverage2dp,
      reviewCount: work.reviewCount,
      duration: work.duration,
      userRating: isLocal ? 0 : (workStatus?.value?.userRating ?? 0),
      vas: work.vas,
      tags: work.tags,
      isLocal: isLocal,
      reviewLabel: reviewLabel,
      onReviewTap: isLocal ? null : () => _showReviewSheet(context, ref, work, workStatus),
      onDrawerOpen: () => KikoenaiInnerDrawerScope.of(context).open(),
      onCircleTap: () => _navigateToCategory(context, ref, work.name),
      onRatingUpdate: isLocal
          ? (int _) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('本地模式下无法提交评价')),
            )
          : (int newRating) => _submitRating(context, ref, work.id, newRating),
      // 文件区段（sliver）
      fileSection: fileSection,
      // 下拉刷新（仅网络）
      onRefresh: isLocal
          ? null
          : () => ref.refresh(trackFileNodeIndexProvider(work.id).future),
    );
  }

  void _showReviewSheet(
    BuildContext context,
    WidgetRef ref,
    Work work,
    AsyncValue<Work?>? workStatus,
  ) {
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
            await HandleSubmit.handleRatingSubmit(context, ref, newStatus);
            ref.invalidate(workDetailProvider(work.id));
          },
        );
      },
    );
  }

  void _navigateToCategory(BuildContext context, WidgetRef ref, String? circleName) {
    if (circleName == null) return;
    ref
        .read(searchFilterProvider(FilterModule.category).notifier)
        .toggleTag(TagType.circle.stringValue, circleName);
    context.go(AppRoutes.category);
  }

  void _submitRating(BuildContext context, WidgetRef ref, int workId, int newRating) {
    final currentStatus = UserWorkStatus(workId: workId);
    final newStatus = currentStatus.copyWith(rating: newRating, workId: workId);
    HandleSubmit.handleRatingSubmit(context, ref, newStatus);
    ref.invalidate(workDetailProvider(workId));
  }
}

// ---------------------------------------------------------------------------
// 纯显示组件（仅接收拆分字段，不感知 Work）
// ---------------------------------------------------------------------------

class AlbumDetailView extends StatelessWidget {
  const AlbumDetailView({
    super.key,
    // 封面
    required this.heroTag,
    this.thumbnailCoverUrl,
    this.mainCoverUrl,
    // 头部
    required this.workId,
    this.title,
    this.circleName,
    // 价格 / 销量
    this.price,
    this.dlCount,
    // 评分
    this.rateAverage2dp,
    this.reviewCount,
    this.duration,
    this.userRating,
    // 标签
    this.vas,
    this.tags,
    // 顶部操作
    required this.isLocal,
    this.reviewLabel,
    this.onReviewTap,
    required this.onDrawerOpen,
    // 交互回调
    required this.onCircleTap,
    required this.onRatingUpdate,
    // 文件区段（sliver）
    required this.fileSection,
    // 下拉刷新
    this.onRefresh,
  });

  // --- 封面 ---
  final String heroTag;
  final String? thumbnailCoverUrl;
  final String? mainCoverUrl;

  // --- 头部 ---
  final int workId;
  final String? title;
  final String? circleName;

  // --- 价格 / 销量 ---
  final int? price;
  final int? dlCount;

  // --- 评分 ---
  final double? rateAverage2dp;
  final int? reviewCount;
  final int? duration;
  final int? userRating;

  // --- 标签 ---
  final List<VA>? vas;
  final List<Tag>? tags;

  // --- 顶部操作 ---
  final bool isLocal;
  /// 评价按钮文本；null 表示加载中（显示 spinner）。仅 !isLocal 时使用。
  final String? reviewLabel;
  final VoidCallback? onReviewTap;
  final VoidCallback onDrawerOpen;

  // --- 交互回调 ---
  final VoidCallback onCircleTap;
  final ValueChanged<int> onRatingUpdate;

  // --- 文件区段 ---
  final Widget fileSection;

  // --- 下拉刷新 ---
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('RJ0$workId', style: const TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        actions: _buildActions(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          final cover = AlbumCover(
            heroTag: heroTag,
            thumbnailUrl: thumbnailCoverUrl,
            mainUrl: mainCoverUrl,
          );
          final info = _buildInfo();

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

          final scrollBody = CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: metadata,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              fileSection,
            ],
          );

          if (onRefresh == null) return scrollBody;
          return RefreshIndicator(onRefresh: onRefresh!, child: scrollBody);
        },
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      if (isLocal)
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            '本地作品',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      else
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onReviewTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bookmark_add_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
                reviewLabel == null
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(reviewLabel!, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.menu_open),
        onPressed: onDrawerOpen,
      ),
    ];
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (circleName != null)
          GestureDetector(
            onTap: onCircleTap,
            child: Text(
              circleName!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 4),
        if (vas != null) TagRow(tags: vas!, type: TagType.va),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${price ?? 0} JPY',
              style: const TextStyle(fontSize: 20, color: Colors.red),
            ),
            const SizedBox(width: 20),
            Text(
              '销量: ${dlCount ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RatingSection(
          average: rateAverage2dp ?? 0,
          userRating: userRating ?? 0,
          extraWidgets: [
            RatingMetaItem(icon: Icons.comment, text: '(${reviewCount ?? 0})'),
            if ((duration ?? 0) > 0)
              RatingMetaItem(
                icon: Icons.timer,
                text: '(${TimeFormatter.formatSeconds(duration!)})',
              ),
          ],
          onRatingUpdate: onRatingUpdate,
        ),
        const SizedBox(height: 12),
        if (tags != null) TagRow(tags: tags!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 加载态 Scaffold
// ---------------------------------------------------------------------------

class _AlbumDetailLoadingScaffold extends StatelessWidget {
  const _AlbumDetailLoadingScaffold({required this.workId});
  final int workId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('RJ0$workId', style: const TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// 封面
// ---------------------------------------------------------------------------

class AlbumCover extends StatelessWidget {
  final String? thumbnailUrl;
  final String? mainUrl;
  final String heroTag;

  const AlbumCover({
    super.key,
    required this.heroTag,
    this.thumbnailUrl,
    this.mainUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
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
