import 'package:flutter/material.dart';
import 'package:kikoenai/core/utils/data/other.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/utils/data/device_storage_util.dart';
import '../../../../core/widgets/layout/app_toast.dart';

class CacheManagementPage extends StatefulWidget {
  const CacheManagementPage({super.key});

  @override
  State<CacheManagementPage> createState() => _CacheManagementPageState();
}

class _CacheManagementPageState extends State<CacheManagementPage> {
  bool _isLoading = true;
  List<_CacheItem> _cacheItems = [];

  // 用于保存设备真实的存储数据
  int _deviceTotalSpace = 0;
  int _deviceFreeSpace = 0;

  // 根据你的 AppStorage 结构定义的缓存项
  final List<Map<String, dynamic>> _boxDefinitions = [
    {
      'name': BoxNames.scraper,
      'label': '元数据缓存',
      'desc': '浏览和爬取作品过程中产生的封面、详情数据，清理后不影响正常使用，可提高流畅性。',
      'dangerous': false,
    },
    {
      'name': BoxNames.scanner,
      'label': '媒体库索引',
      'desc': '本地扫描生成的媒体元数据，清理后需重新扫描本地目录恢复。',
      'dangerous': false,
    },
    {
      'name': BoxNames.history,
      'label': '播放历史记录',
      'desc': '音频进度断点、最近播放列表等记录信息。',
      'dangerous': false,
    },
    {
      'name': BoxNames.playerState,
      'label': '播放器状态',
      'desc': '退出应用时保存的音量、播放模式等临时状态。',
      'dangerous': false,
    },
    {
      'name': BoxNames.auth,
      'label': '登录凭证 (敏感)',
      'desc': '用户登录状态与 Token 信息，清理后将导致账号强制登出。',
      'dangerous': true,
    },
    {
      'name': BoxNames.settings,
      'label': '系统配置 (敏感)',
      'desc': '应用偏好设置、深色模式状态等，清理后应用将恢复默认设置。',
      'dangerous': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCacheSizes();
  }

  /// 通过 AppStorage 加载真实数据
  Future<void> _loadCacheSizes({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    try {
      // 1. 并行获取设备真实磁盘信息，避免串行阻塞时间过长
      // 注意：请确保你的 DeviceStorageUtil 路径已正确导入
      final storageResults = await Future.wait([
        DeviceStorageUtil.getTotalSpace(),
        DeviceStorageUtil.getFreeSpace(),
      ]);
      _deviceTotalSpace = storageResults[0];
      _deviceFreeSpace = storageResults[1];

      // 2. 遍历获取各个 Box 的体积
      final List<_CacheItem> items = [];
      for (var def in _boxDefinitions) {
        final boxName = def['name'] as String;
        final size = await AppStorage.getBoxSize(boxName);
        items.add(_CacheItem(
          boxName: boxName,
          label: def['label'] as String,
          description: def['desc'] as String,
          isDangerous: def['dangerous'] as bool,
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
        KikoenaiToast.error("获取数据失败: $e", context: context);
        setState(() => _isLoading = false);
      }
    }
  }

  /// 执行清理逻辑
  Future<void> _clearCache(_CacheItem item) async {
    _showCleanConfirmation(
      title: '清理 ${item.label}',
      content: item.isDangerous
          ? '警告：此为敏感数据，${item.description}确定要继续清理吗？'
          : '确定要清空该项数据吗？此操作不可恢复。',
      isDangerous: item.isDangerous,
      onConfirm: () async {
        try {
          await AppStorage.clearBox(item.boxName);
          if (!mounted) return;
          KikoenaiToast.success("${item.label} 已清理", context: context);
          _loadCacheSizes(showLoading: false);
        } catch (e) {
          if (mounted) {
            KikoenaiToast.error("清理失败: $e", context: context);
          }
        }
      },
    );
  }

  /// 确认弹窗
  Future<void> _showCleanConfirmation({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
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
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTotalBytes = _cacheItems.fold<int>(0, (sum, item) => sum + item.sizeBytes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('存储空间', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. 顶部总容量与进度条
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: _buildStorageHeader(context, appTotalBytes),
            ),
          ),

          // 2. 缓存项列表 (放置在同一张大卡片内)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  child: Column(
                    children: _cacheItems.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final _CacheItem item = entry.value;
                      final bool isLast = idx == _cacheItems.length - 1;
                      return _buildCacheItemCard(context, item, isLast);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  /// 顶部真实存储统计面板
  Widget _buildStorageHeader(BuildContext context, int appUsedBytes) {
    final theme = Theme.of(context);

    // 1. 数据校验与兜底逻辑（防止插件获取失败导致除零错误）
    final bool hasRealData = _deviceTotalSpace > 0;
    final int total = hasRealData ? _deviceTotalSpace : 10737418240; // 兜底 10GB
    final int free = hasRealData ? _deviceFreeSpace : total ~/ 2;

    // 2. 计算各项占用真实体积
    int otherUsedBytes = total - free - appUsedBytes;
    if (otherUsedBytes < 0) otherUsedBytes = 0;

    // 3. 计算用于渲染的 Flex 比例
    double appRatio = appUsedBytes / total;

    // 视觉锚点处理：如果 App 占用微乎其微（如电脑上的几MB占几百GB不足1%）
    // 强行设定最小视觉比例，防止红色进度条在 UI 上完全消失看不见
    bool isAppTiny = appRatio > 0 && appRatio < 0.01;
    if (isAppTiny) appRatio = 0.01;

    double freeRatio = free / total;
    double otherRatio = 1.0 - appRatio - freeRatio;
    if (otherRatio < 0) otherRatio = 0;

    // 转换为整数提供给 Flex
    final int appFlex = (appRatio * 1000).toInt();
    final int otherFlex = (otherRatio * 1000).toInt();
    final int freeFlex = (freeRatio * 1000).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kikoenai 占用',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          OtherUtil.formatBytes(appUsedBytes),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontFamily: 'Monospace',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),

        // 基于底层真实数据的进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (appFlex > 0)
                  Expanded(flex: appFlex, child: Container(color: theme.colorScheme.error)),
                if (otherFlex > 0)
                  Expanded(flex: otherFlex, child: Container(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5))),
                if (freeFlex > 0)
                  Expanded(flex: freeFlex, child: Container(color: theme.colorScheme.surfaceContainerHighest)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 图例还原：采用全平台通用文案
        Row(
          children: [
            _buildLegendItem(context, theme.colorScheme.error, isAppTiny ? '应用占用不足 1%' : '应用占用'),
            const SizedBox(width: 16),
            _buildLegendItem(context, theme.colorScheme.onSurfaceVariant.withOpacity(0.5), '设备已用'),
            const SizedBox(width: 16),
            _buildLegendItem(context, theme.colorScheme.surfaceContainerHighest, '设备可用'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// 缓存列表单项 (还原图片下半部分的每一行)
  Widget _buildCacheItemCard(BuildContext context, _CacheItem item, bool isLast) {
    final theme = Theme.of(context);
    final bool hasData = item.sizeBytes > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：标题 + 小问号(可选)
              Row(
                children: [
                  Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.help_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 第二行：巨型尺寸字 + 右侧清理按钮
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      OtherUtil.formatBytes(item.sizeBytes),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ),

                  // 按钮区域
                  SizedBox(
                    height: 32,
                    child: item.isDangerous
                        ? OutlinedButton(
                      onPressed: hasData ? () => _clearCache(item) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: hasData ? theme.colorScheme.error : theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('管理', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    )
                        : FilledButton(
                      onPressed: hasData ? () => _clearCache(item) : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('清理', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第三行：灰色说明文本
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        // 底部分割线
        if (!isLast)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: theme.dividerColor.withOpacity(0.3),
          ),
      ],
    );
  }
}

// 简单数据模型
class _CacheItem {
  final String boxName;
  final String label;
  final String description;
  final bool isDangerous;
  final int sizeBytes;

  _CacheItem({
    required this.boxName,
    required this.label,
    required this.description,
    required this.isDangerous,
    required this.sizeBytes,
  });
}