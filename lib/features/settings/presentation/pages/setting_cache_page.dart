import 'package:flutter/material.dart';
import 'package:kikoenai/core/utils/data/other.dart';

import 'package:kikoenai/core/storage/hive_box.dart';

import '../../../../core/widgets/layout/app_toast.dart';
import '../../../../../core/service/cache_service.dart';

class CacheManagementPage extends StatefulWidget {
  const CacheManagementPage({super.key});

  @override
  State<CacheManagementPage> createState() => _CacheManagementPageState();
}

class _CacheManagementPageState extends State<CacheManagementPage> {
  bool _isLoading = true;
  List<_CacheItem> _cacheItems = [];

  final List<Map<String, dynamic>> _boxDefinitions = [
    {
      'name': BoxNames.settings,
      'label': '系统配置',
      'desc': '应用偏好设置、搜索记录',
      'icon': Icons.settings_system_daydream_rounded,
    },
    {
      'name': BoxNames.auth,
      'label': '登录凭证',
      'desc': '用户登录状态信息',
      'icon': Icons.verified_user_rounded,
    },
    {
      'name': BoxNames.history,
      'label': '播放历史',
      'desc': '音频进度断点、播放列表',
      'icon': Icons.history_rounded,
    },
    {
      'name': BoxNames.playerState,
      'label': '播放器状态',
      'desc': '退出时的音量、播放模式',
      'icon': Icons.music_note_rounded,
    },
    {
      'name': BoxNames.scanner,
      'label': '媒体库索引',
      'desc': '本地扫描的媒体元数据',
      'icon': Icons.folder_open_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCacheSizes();
  }

  Future<void> _loadCacheSizes({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final List<_CacheItem> items = [];
      for (var def in _boxDefinitions) {
        final boxName = def['name'] as String;
        final size = await CacheService.instance.getBoxFileSize(boxName);
        items.add(_CacheItem(
          boxName: boxName,
          label: def['label'] as String,
          description: def['desc'] as String,
          icon: def['icon'] as IconData,
          sizeBytes: size,
        ));
      }

      if (mounted) {
        setState(() {
          _cacheItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        KikoenaiToast.error(
          "获取数据失败: $e",
          context: context,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCleanConfirmation({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.black : Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDangerous ? Theme.of(context).colorScheme.error : null,
                        foregroundColor: isDangerous ? Theme.of(context).colorScheme.onError : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('确认清理'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache(_CacheItem item) async {
    final isSensitive = item.boxName == BoxNames.settings || item.boxName == BoxNames.auth;

    _showCleanConfirmation(
      title: '清理 ${item.label}?',
      content: isSensitive
          ? '警告：此操作可能导致您退出登录或重置应用设置。'
          : '确定要清空该项数据吗？此操作不可恢复。',
      isDangerous: isSensitive,
      onConfirm: () async {
        try {
          await CacheService.instance.clearBox(item.boxName);
          if (!mounted) return;
          KikoenaiToast.success(
            "${item.label} 已清理",
            context: context,
          );
          _loadCacheSizes(showLoading: false);
        } catch (e) {
          if (mounted) {
            KikoenaiToast.error("清理失败: $e", context: context);
          }
        }
      },
    );
  }

  Future<void> _clearAll() async {
    _showCleanConfirmation(
      title: '释放所有空间',
      content: '这将重置应用的所有本地数据，包括登录状态、历史记录和索引缓存。应用将恢复到初始状态。',
      isDangerous: true,
      onConfirm: () async {
        try {
          for (var item in _cacheItems) {
            await CacheService.instance.clearBox(item.boxName);
          }
          if (!mounted) return;
          KikoenaiToast.success("所有缓存已清理", context: context);
          _loadCacheSizes(showLoading: false);
        } catch (e) {
          if (mounted) {
            KikoenaiToast.error("部分清理失败: $e", context: context);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBytes = _cacheItems.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainBackgroundColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: mainBackgroundColor,
      appBar: AppBar(
        title: const Text('存储空间'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        // 如果背景是纯色，AppBar可能需要稍微调整下颜色或保持透明
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. 顶部仪表盘 (无卡片背景)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 30),
              child: _buildDashboardCard(context, totalBytes),
            ),
          ),

          // 2. 详细列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = _cacheItems[index];
                final double percentage = totalBytes == 0 ? 0.0 : item.sizeBytes / totalBytes;
                // 判断是否是最后一个，如果是则不显示分割线
                final isLast = index == _cacheItems.length - 1;
                return _buildCacheItemRow(context, item, percentage, isLast);
              },
              childCount: _cacheItems.length,
            ),
          ),

          const SliverGap(height: 100),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: totalBytes > 0
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _clearAll,
            style: FilledButton.styleFrom(
              // 按钮保持一定的视觉重量，方便点击
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.cleaning_services_rounded),
            label: Text('一键释放 ${OtherUtil.formatBytes(totalBytes)}'),
          ),
        ),
      )
          : null,
    );
  }

  // --- UI 组件 (重构版) ---

  /// 仪表盘：移除背景，专注于大字体排版
  Widget _buildDashboardCard(BuildContext context, int totalBytes) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08), // 非常淡的背景圆圈
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pie_chart_rounded, size: 48, color: colorScheme.primary),
        ),
        const SizedBox(height: 20),
        Text(
          OtherUtil.formatBytes(totalBytes),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            fontFamily: 'Monospace', // 保持等宽数字的美感
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '占用空间',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 列表项：无卡片背景，使用分割线布局
  Widget _buildCacheItemRow(BuildContext context, _CacheItem item, double percentage, bool isLast) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool canClear = item.sizeBytes > 1024;

    return InkWell(
      onTap: canClear ? () => _clearCache(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                // 1. 图标：保留一个柔和的背景，作为视觉锚点
                Container(
                  width: 48,
                  height: 48,
                  child: Icon(item.icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),

                // 2. 文字信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 3. 右侧操作区
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      OtherUtil.formatBytes(item.sizeBytes),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: canClear ? colorScheme.onSurface : colorScheme.outline,
                        fontFamily: 'Monospace',
                      ),
                    ),
                    if (canClear) ...[
                      const SizedBox(height: 4),
                      Text(
                        '清除',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // 4. 进度条 (嵌入在文字下方)
            if (percentage > 0.01) ...[
              const SizedBox(height: 12),
              // 向右偏移以对齐文字，看起来更整洁
              Padding(
                padding: const EdgeInsets.only(left: 64),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    color: colorScheme.primary.withOpacity(0.7),
                    minHeight: 4, // 更细的进度条
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // 5. 分割线 (如果是最后一个则不显示)
            if (!isLast)
              Divider(
                height: 1,
                indent: 64, // 对齐文字起始位置
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
          ],
        ),
      ),
    );
  }
}

class SliverGap extends StatelessWidget {
  final double height;
  const SliverGap({super.key, required this.height});
  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: SizedBox(height: height));
}

class _CacheItem {
  final String boxName;
  final String label;
  final String description;
  final IconData icon;
  final int sizeBytes;

  _CacheItem({
    required this.boxName,
    required this.label,
    required this.description,
    required this.icon,
    required this.sizeBytes,
  });
}