import 'package:flutter/material.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/widgets/layout/app_toast.dart';

import '../../../../core/service/cache_service.dart';

class CacheManagementPage extends StatefulWidget {
  const CacheManagementPage({super.key});

  @override
  State<CacheManagementPage> createState() => _CacheManagementPageState();
}

class _CacheManagementPageState extends State<CacheManagementPage> {
  bool _isLoading = true;
  List<_CacheItem> _cacheItems = [];

  // 定义配置：增加 icon 字段
  final List<Map<String, dynamic>> _boxDefinitions = [
    {
      'name': BoxNames.cache,
      'label': '系统配置',
      'desc': '登录态、设置、搜索记录',
      'icon': Icons.settings_system_daydream_rounded,
    },
    {
      'name': BoxNames.history,
      'label': '播放历史',
      'desc': '音频进度断点、播放列表',
      'icon': Icons.history_rounded,
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

  Future<void> _loadCacheSizes() async {
    setState(() => _isLoading = true);
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
        AppToast.error(context, "获取数据失败: $e");
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
    _showCleanConfirmation(
      title: '清理 ${item.label}?',
      content: item.boxName == BoxNames.cache
          ? '警告：清除系统配置将导致您退出登录，并重置所有应用偏好设置。'
          : '确定要清空该项数据吗？此操作不可恢复。',
      isDangerous: item.boxName == BoxNames.cache,
      onConfirm: () async {
        try {
          await CacheService.instance.clearBoxFile(item.boxName);
          AppToast.success(context, "${item.label} 已清理");
          _loadCacheSizes();
        } catch (e) {
          AppToast.error(context, "清理失败: $e");
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
        for (var item in _cacheItems) {
          await CacheService.instance.clearBoxFile(item.boxName);
        }
        AppToast.success(context, "所有缓存已清理");
        _loadCacheSizes();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBytes = _cacheItems.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // 使用最底层的背景色
      appBar: AppBar(
        title: const Text('存储空间'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. 顶部仪表盘
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildDashboardCard(context, totalBytes),
            ),
          ),

          // 2. 列表标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                '详细数据',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 3. 详细列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = _cacheItems[index];
                // 计算占比，用于进度条
                final double percentage = totalBytes == 0 ? 0.0 : item.sizeBytes / totalBytes;
                return _buildCacheItemCard(context, item, percentage);
              },
              childCount: _cacheItems.length,
            ),
          ),

          // 底部留白
          const SliverGap(height: 80),
        ],
      ),
      // 悬浮的底部按钮
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: totalBytes > 0
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _clearAll,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
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

  Widget _buildDashboardCard(BuildContext context, int totalBytes) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // 稍微亮一点的背景
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            OtherUtil.formatBytes(totalBytes),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              fontFamily: 'Monospace', // 使用等宽字体显示数字更有科技感
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '当前占用空间',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheItemCard(BuildContext context, _CacheItem item, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.sizeBytes > 0 ? () => _clearCache(item) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // 图标容器
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),

                  // 文本信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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

                  // 大小显示
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        OtherUtil.formatBytes(item.sizeBytes),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.sizeBytes > 0 ? colorScheme.onSurface : colorScheme.outline,
                        ),
                      ),
                      if(item.sizeBytes > 0)
                        Text(
                          '清除',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        )
                    ],
                  ),
                ],
              ),

              // 进度条 (仅当有大小时显示)
              if (percentage > 0.01) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    color: colorScheme.primary.withOpacity(0.8),
                    minHeight: 6,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// 辅助组件：用于 Sliver 间距
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
  final IconData icon; // 新增 Icon
  final int sizeBytes;

  _CacheItem({
    required this.boxName,
    required this.label,
    required this.description,
    required this.icon,
    required this.sizeBytes,
  });
}